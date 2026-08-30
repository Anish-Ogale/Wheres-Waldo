# Where's Waldo 

A custom convolution engine on an FPGA that powers a real time YOLO object detection model, capturing live video and identifying objects in a scene


## Programmable Logic Pipeline

### Processing Pipeline : 


* **Tiling Buffers :** Since the entire feature map cannot fit on, we use buffers to send pixel and weight data to the calculation block for multiplication.
* **Calculation Block:** Consists of an 8x8 weight stationary systolic array to perform matrix multiplications.
* **AXI Burst:** Custom AXI code which sends data in bursts instead of single pixel by pixel which reduces number of memory addresses and improves speed.
* **Post Processing** Data from matrix multiplication outputs is first accumulated for complete sums, after which Leaky ReLU, 8 bit quantization and pooling is performed on it.

![WhatsApp Image 2026-08-30 at 1 43 03 PM](https://github.com/user-attachments/assets/b6a5f7be-5d75-48af-9d76-e10fb880e41e)

### PL Flow

Pixel data flows in to the DDR3. The image is sent tile by tile to the input ping pong buffers. It is then skewed and passed through the systolic array for matrix multiplication with the weights which are tracked via the weight buffer. 

The partial sums are accumulated into complete sums in the accumulator module. Leaky ReLU is performed, followed by 8 bit quantization. Lastly, pooling is performed depending on the layer. 


The processed pixels are sent back to DDR3 via output buffers, and sent back via AXI Burst.


![WhatsApp Image 2026-08-30 at 1 43 15 PM](https://github.com/user-attachments/assets/0dd3816c-ce53-4a69-9c43-6ac1db777c87)



### Camera Pipeline Flow
The OV7670 outputs raw parallel video (PCLK, VSYNC, HREF, and a 6-bit data bus) rather than a standard streaming interface, so custom RTL was written to convert it into an AXI4-Stream. Before capture, the sensor is configured over SCCB (an I2C-like protocol) to set resolution (QVGA) and output format (RGB565).

Three RTL modules handle this conversion:
* **byte_pair_merge** - reassembles two consecutive 6-bit bus reads (high byte, then low byte) into a single 16-bit RGB565 pixel, since OV7670 sends each pixel across 2 PCLK cycles.
* **frame_sync** - detects start-of-frame from VSYNC's falling edge and generates a clean, synchronous start-of-frame pulse.
* **ov7670_capture** - top-level module combining both, producing a proper AXI4-Stream output.

![Screenshot 2026-08-30 133045](https://github.com/user-attachments/assets/0653c92b-67a8-49ad-b485-d2f69f5199db)


Since the camera's pixel clock domain is asynchronous to the system/AXI clock, the stream is passed through an AXI4-Stream Data FIFO (independent-clocks mode) to safely cross clock domains before reaching memory.

From there, AXI VDMA IP (S2MM channel) writes incoming frames into DDR3 with triple buffering, offloading the ARM core (PS) from copying pixel data manually. Camera control (SCCB) and reset/power-down lines are driven via two AXI GPIO IPs, and a Clocking Wizard generates the 24 MHz XCLK the sensor requires.

![Screenshot 2026-08-30 133101](https://github.com/user-attachments/assets/624a831d-7b4e-4d73-bc27-bb5d8ba73fff)


## Hardware and Software Used
* **Board:** Xilinx Zynq-7000 SoC ZC702 Evaluation Kit
* **Peripherals:** OV7670 Camera Module, Pullup resistors for PWDN and RST.
* **Softwares:** Xilinx Vivado, Vitis Unified IDE
