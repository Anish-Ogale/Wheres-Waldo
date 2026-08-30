#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include "xparameters.h"
#include "xgpio.h"
#include "xil_printf.h"
#include "xil_cache.h"
#include "sleep.h"

// Hardware Addresses (Matched to address_gen.sv)
#define WEIGHT_BASE_ADDR 0x00000000
#define IFM_BASE_ADDR    0x00F21000 // Layer 0 Input
#define OFM_BASE_ADDR    0x01156000 // Layer 8 Output

// YOLO Configuration
#define GRID_W 13
#define GRID_H 13
#define NUM_ANCHORS 5
#define NUM_CLASSES 20
#define OUTPUT_CHANNELS (NUM_ANCHORS * (5 + NUM_CLASSES))

#include "xuartps.h"

// Hardware Peripherals
XGpio ctrl_gpio;
XUartPs uart;

// A simple Sigmoid function
float sigmoid(float x) {
    return 1.0f / (1.0f + expf(-x));
}

// A simple Softmax function (applied in-place to an array of class scores)
void softmax(float *classes, int num_classes) {
    float max_val = classes[0];
    for (int i = 1; i < num_classes; i++) {
        if (classes[i] > max_val) max_val = classes[i];
    }
    
    float sum = 0.0f;
    for (int i = 0; i < num_classes; i++) {
        classes[i] = expf(classes[i] - max_val); // Subtract max for numerical stability
        sum += classes[i];
    }
    
    for (int i = 0; i < num_classes; i++) {
        classes[i] /= sum;
    }
}

// Receive data from UART with ACK handshake
void receive_data_from_pc(uint8_t* dest_addr, int expected_bytes, const char* name) {
    xil_printf("\r\nWaiting for %s (%d bytes)...\r\n", name, expected_bytes);
    
    int received_bytes = 0;
    int chunk_size = 4096;
    
    while (received_bytes < expected_bytes) {
        int bytes_to_read = expected_bytes - received_bytes;
        if (bytes_to_read > chunk_size) bytes_to_read = chunk_size;
        
        int chunk_received = 0;
        while (chunk_received < bytes_to_read) {
            chunk_received += XUartPs_Recv(&uart, dest_addr + received_bytes + chunk_received, bytes_to_read - chunk_received);
        }
        received_bytes += chunk_received;
        
        // Send ACK back to PC so it sends the next chunk
        u8 ack = 'A';
        XUartPs_Send(&uart, &ack, 1);
    }
    xil_printf("%s fully received and stored in DDR!\r\n", name);
}

int main() {
    xil_printf("\r\n--- Zynq YOLOv2 Hardware Accelerator ---\r\n");

    // 1. Initialize the AXI GPIO
    XGpio_Config *gpio_cfg = XGpio_LookupConfig(XPAR_AXI_GPIO_0_DEVICE_ID); 
    if (gpio_cfg == NULL) {
        xil_printf("GPIO Lookup Failed! Trying Device ID 0...\r\n");
        gpio_cfg = XGpio_LookupConfig(0);
        if (gpio_cfg == NULL) {
            return XST_FAILURE;
        }
    }
    
    if (XGpio_CfgInitialize(&ctrl_gpio, gpio_cfg, gpio_cfg->BaseAddress) != XST_SUCCESS) {
        xil_printf("GPIO Init Failed!\r\n");
        return XST_FAILURE;
    }
    
    XGpio_SetDataDirection(&ctrl_gpio, 1, 0x0); 
    XGpio_SetDataDirection(&ctrl_gpio, 2, 0x1);

    // Initialize UART
    XUartPs_Config *uart_cfg = XUartPs_LookupConfig(XPAR_XUARTPS_0_DEVICE_ID);
    XUartPs_CfgInitialize(&uart, uart_cfg, uart_cfg->BaseAddress);
    XUartPs_SetBaudRate(&uart, 921600);

    // 2. Load the Weights into DDR memory (15,855,536 bytes)
    uint8_t* weight_memory = (uint8_t*)WEIGHT_BASE_ADDR;
    receive_data_from_pc(weight_memory, 15855536, "YOLO Weights");

    // 3. Load the Image into DDR memory (1,384,448 bytes)
    uint8_t* ifm_memory = (uint8_t*)IFM_BASE_ADDR;
    receive_data_from_pc(ifm_memory, 1384448, "Image");

    // 3. Flush the Data Cache! 
    // This forces the ARM processor to push the loaded image out of its L1/L2 cache and into the physical DDR chips.
    Xil_DCacheFlush();

    // 4. Trigger the Hardware Pipeline
    xil_printf("Triggering FPGA Pipeline...\r\n");
    XGpio_DiscreteWrite(&ctrl_gpio, 1, 1); // start = 1
    usleep(10);
    XGpio_DiscreteWrite(&ctrl_gpio, 1, 0); // start = 0

    // 5. Wait for Completion
    while (XGpio_DiscreteRead(&ctrl_gpio, 2) == 0) {
        // Poll the 'done' signal. The hardware takes ~1 second at 100MHz.
    }
    xil_printf("FPGA Processing Complete!\r\n");

    // 6. Invalidate the Cache
    // The FPGA wrote the results directly to physical DDR. We must invalidate the ARM cache 
    // so it doesn't read stale memory when we fetch the results.
    Xil_DCacheInvalidateRange(OFM_BASE_ADDR, GRID_W * GRID_H * OUTPUT_CHANNELS);

    // 7. Post-Processing (YOLO Softmax & Sigmoid)
    int8_t* ofm_memory = (int8_t*)OFM_BASE_ADDR;
    
    xil_printf("Parsing Bounding Boxes...\r\n");
    
    // Loop through the 13x13 grid
    for (int y = 0; y < GRID_H; y++) {
        for (int x = 0; x < GRID_W; x++) {
            
            // Loop through the 5 anchor boxes per grid cell
            for (int a = 0; a < NUM_ANCHORS; a++) {
                
                // Calculate the memory offset for this specific anchor
                int offset = (y * GRID_W * OUTPUT_CHANNELS) + (x * OUTPUT_CHANNELS) + (a * (5 + NUM_CLASSES));
                
                // Note: The hardware outputs INT8. You would normally multiply these by your 
                // quantization scale factor here to convert them back to floats. 
                // For this example, we'll cast them directly to floats.
                float tx = (float)ofm_memory[offset + 0];
                float ty = (float)ofm_memory[offset + 1];
                float tw = (float)ofm_memory[offset + 2];
                float th = (float)ofm_memory[offset + 3];
                float to = (float)ofm_memory[offset + 4]; // Objectness score
                
                // 1. Apply Sigmoid to X, Y, and Objectness
                float bx = sigmoid(tx) + x;
                float by = sigmoid(ty) + y;
                float objectness = sigmoid(to);
                
                // 2. Apply Exponential to W and H
                // (Note: you would multiply by the pre-defined Anchor Box biases here)
                float bw = expf(tw);
                float bh = expf(th);
                
                // 3. Apply Softmax to the 20 Class Scores
                float classes[NUM_CLASSES];
                for (int c = 0; c < NUM_CLASSES; c++) {
                    classes[c] = (float)ofm_memory[offset + 5 + c];
                }
                softmax(classes, NUM_CLASSES);
                
                // 4. Thresholding (e.g., Confidence > 50%)
                if (objectness > 0.5f) {
                    // Find the class with the highest probability
                    int best_class = 0;
                    float best_prob = classes[0];
                    for(int c = 1; c < NUM_CLASSES; c++){
                        if(classes[c] > best_prob){
                            best_prob = classes[c];
                            best_class = c;
                        }
                    }
                    
                    xil_printf("Found Object! Class: %d, Confidence: %d%%\r\n", best_class, (int)(objectness * best_prob * 100));
                }
            }
        }
    }
    
    // (Non-Maximum Suppression would go here to filter overlapping boxes)
    
    xil_printf("Done.\r\n");
    return 0;
}
