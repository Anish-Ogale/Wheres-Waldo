`timescale 1ns / 1ps

module tb_deskewer();

    parameter SIZE = 8;
    
    // Testbench Signals (Updated to 32-bit)
    reg clk;
    reg signed [31:0] pixel_in [0:SIZE-1];
    wire signed [31:0] pixel_out [0:SIZE-1];

    // Instantiate the module
    deskewer #(.size(SIZE)) uut (
        .clk(clk),
        .pixel_in(pixel_in),
        .pixel_out(pixel_out)
    );

    // Clock Generator (10ns period)
    always #5 clk = ~clk;

    // Stimulus Block
    initial begin
        // 1. Initialize clock and inputs to 0
        clk = 0;
        for(int i=0; i<SIZE; i++) begin
            pixel_in[i] = 32'd0;
        end
        
        // Wait for two positive clock edges
        @(posedge clk);
        @(posedge clk);
        
        // 2. Fire a single pulse of 1s using Non-Blocking Assignments
        for(int i=0; i<SIZE; i++) begin
            pixel_in[i] <= 32'd1;
        end
        
        // Wait for the next positive clock edge
        @(posedge clk);
        
        // 3. Return all inputs to 0 synchronously
        for(int i=0; i<SIZE; i++) begin
            pixel_in[i] <= 32'd0;
        end
        
        // 4. Wait enough time for the pulse to exit the 7-delay chain
        #100;
        
        $finish;
    end

    // Console Monitor
    initial begin
        $display("Time | Out0 | Out1 | Out2 | Out3 | Out4 | Out5 | Out6 | Out7");
        $display("---------------------------------------------------------------");
        // Updated to %d for readable 32-bit decimal formatting
        $monitor("%4t |   %d  |   %d  |   %d  |   %d  |   %d  |   %d  |   %d  |   %d", 
                 $time, 
                 pixel_out[0], pixel_out[1], pixel_out[2], pixel_out[3], 
                 pixel_out[4], pixel_out[5], pixel_out[6], pixel_out[7]);
    end

endmodule
