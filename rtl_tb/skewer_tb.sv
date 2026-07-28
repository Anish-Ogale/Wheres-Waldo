`timescale 1ns / 1ps


module tb_skewer();

    parameter SIZE = 8;
    
    // Testbench Signals
    reg clk;
    reg signed [7:0] pixel_in [0:SIZE-1];
    wire signed [7:0] pixel_out [0:SIZE-1];

    // Instantiate the module
    skewer #(.size(SIZE)) uut (
        .clk(clk),
        .pixel_in(pixel_in),
        .pixel_out(pixel_out)
    );

    // Clock Generator (10ns period)
    always #5 clk = ~clk;

   // Stimulus Block
   // Stimulus Block
    // Stimulus Block
    initial begin
        // 1. Initialize clock and inputs to 0
        clk = 0;
        for(int i=0; i<SIZE; i++) begin
            pixel_in[i] = 8'd0;
        end
        
        // Wait for two positive clock edges
        @(posedge clk);
        @(posedge clk);
        
        // 2. Fire a pulse using Non-Blocking Assignments (<=)
        for(int i=0; i<SIZE; i++) begin
            pixel_in[i] <= 8'd1;
        end
        
        // Wait for the next positive clock edge
        @(posedge clk);
        
        // 3. Return all inputs to 0 synchronously
        for(int i=0; i<SIZE; i++) begin
            pixel_in[i] <= 8'd0;
        end
        
        // 4. Wait enough time for the pulse to exit the 7-delay chain
        #100;
        
        $finish;
    end

    // Console Monitor
    initial begin
        $display("Time | Out0 | Out1 | Out2 | Out3 | Out4 | Out5 | Out6 | Out7");
        $display("---------------------------------------------------------------");
        $monitor("%4t |   %b  |   %b  |   %b  |   %b  |   %b  |   %b  |   %b  |   %b", 
                 $time, 
                 pixel_out[0], pixel_out[1], pixel_out[2], pixel_out[3], 
                 pixel_out[4], pixel_out[5], pixel_out[6], pixel_out[7]);
    end

endmodule