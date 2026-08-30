`timescale 1ns / 1ps

module conv_tb();

    // ========================================================================
    // Parameters & Signals
    // ========================================================================
    parameter WIDTH  = 32;
    parameter HEIGHT = 32;
    parameter DELAY  = 2*WIDTH + 4;
    
    // UART timing (100MHz clock, 19200 baud)
    localparam BIT_PERIOD = 52080; 

    reg clk;
    reg rst;
    reg rx;
    wire tx;

    // ========================================================================
    // Instantiation
    // ========================================================================
    conv_top uut (
        .clk(clk),
        .rst(rst),
        .rx(rx),
        .tx(tx)
    );

    // ========================================================================
    // Clock Generation (100MHz)
    // ========================================================================
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // ========================================================================
    // File I/O Variables
    // ========================================================================
    integer i;
    integer outfile;
    reg [7:0] image_mem [0:WIDTH*HEIGHT-1];
    
    // Variable to track how many bytes the hardware has successfully returned
    integer received_count = 0;

    // ========================================================================
    // UART Send Task (Simulates PC transmitting a byte to the FPGA)
    // ========================================================================
    task send_byte;
        input [7:0] data;
        integer b;
        begin
            // Start Bit (rx goes low)
            rx = 0;
            #(BIT_PERIOD);
            
            // 8 Data Bits (LSB first)
            for (b = 0; b < 8; b = b + 1) begin
                rx = data[b];
                #(BIT_PERIOD);
            end
            
            // Stop Bit (rx goes high)
            rx = 1;
            #(BIT_PERIOD);
        end
    endtask

    // ========================================================================
    // Main Stimulus: Read File & Transmit
    // ========================================================================
    initial begin
        // 1. Load the input image into memory
        // Update this path to match the local directory structure!
        $readmemb("/home/sra-admin/whereswaldo/Wheres-Waldo/Task_2/input_image.bin", image_mem);
        
        // 2. Open the output file for writing
        outfile = $fopen("output_image.bin", "w");
        if (outfile == 0) begin
            $display("ERROR: Could not open output file.");
            $finish;
        end

        // 3. Initialize and Reset
        rx = 1; // Idle state for UART RX is HIGH
        rst = 1;
        #100;
        rst = 0;
        #1000;

        $display("[%0t ns] Starting UART Transmission of %0d pixels...", $time, WIDTH*HEIGHT);

        // 4. Send the actual image bytes
        for (i = 0; i < WIDTH*HEIGHT; i = i + 1) begin
            send_byte(image_mem[i]);
        end

        $display("[%0t ns] Finished sending image data. Sending dummy bytes to flush pipeline...", $time);

        // 5. Send dummy bytes to flush the final rows out of the morphology pipeline
        for (i = 0; i < DELAY; i = i + 1) begin
            send_byte(8'h00);
        end
        
        // Note: We don't $finish here. We must wait for the receive block 
        // to collect all the bytes first.
    end

    // ========================================================================
    // Parallel Monitor: Receive UART Data & Write File
    // ========================================================================
    reg [7:0] received_byte;
    
    initial begin
        forever begin
            // Wait for a falling edge on tx (Start bit from FPGA)
            @(negedge tx);
            
            // Wait half a bit period to sample exactly in the middle of the start bit
            #(BIT_PERIOD / 2);
            
            // Confirm it's a valid start bit (still 0)
            if (tx == 0) begin
                // Sample 8 data bits
                #(BIT_PERIOD); received_byte[0] = tx; 
                #(BIT_PERIOD); received_byte[1] = tx; 
                #(BIT_PERIOD); received_byte[2] = tx; 
                #(BIT_PERIOD); received_byte[3] = tx; 
                #(BIT_PERIOD); received_byte[4] = tx; 
                #(BIT_PERIOD); received_byte[5] = tx; 
                #(BIT_PERIOD); received_byte[6] = tx; 
                #(BIT_PERIOD); received_byte[7] = tx; 
                
                // Write the received byte to the binary file
                $fwrite(outfile, "%08b\n", received_byte);
                received_count = received_count + 1;
                
                // Optional: Print progress every 10,000 pixels so Vivado doesn't look frozen
                if (received_count % 10000 == 0) begin
                    $display("[%0t ns] Progress: Received %0d / %0d pixels", $time, received_count, WIDTH*HEIGHT);
                end
                
                // 6. Check if the task is complete
                if (received_count == (WIDTH * HEIGHT)) begin
                    $display("[%0t ns] SUCCESS: All %0d pixels received and written.", $time, received_count);
                    $fclose(outfile);
                    $finish;
                end
            end
        end
    end

endmodule
