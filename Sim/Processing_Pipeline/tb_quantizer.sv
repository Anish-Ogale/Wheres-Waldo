`timescale 1ns / 1ps

module tb_quantizer;

    parameter int NUM_CHANNELS = 8;

    logic clk;
    logic rst_n;
    logic in_valid;
    logic out_valid;
    logic signed [15:0] scale;
    logic [4:0] shift;
    logic signed [31:0] in_data [0:NUM_CHANNELS-1];
    logic signed [7:0] out_data [0:NUM_CHANNELS-1];

    // Instantiate UUT
    quantizer #(
        .NUM_CHANNELS(NUM_CHANNELS)
    ) uut (
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(in_valid),
        .out_valid(out_valid),
        .scale(scale),
        .shift(shift),
        .in_data(in_data),
        .out_data(out_data)
    );

    // 100 MHz Clock Generation
    always #5 clk = ~clk;

    initial begin
        clk      = 0;
        rst_n    = 0;
        in_valid = 0;
        scale    = 16'sd16384; // 0.5 in Q15 format
        shift    = 5'd14;      // Effective multiplier = 16384 / 2^14 = 1.0 (Pass-through test)

        for (int i = 0; i < NUM_CHANNELS; i++) in_data[i] = 32'sd0;

        #20 rst_n = 1;
        #10;

        // --- TEST CASE 1: Normal Values inside [-128, 127] ---
        in_valid = 1;
        in_data[0] = 32'sd50;   // Expect 50
        in_data[1] = -32'sd75;  // Expect -75
        in_data[2] = 32'sd0;    // Expect 0
        in_data[3] = 32'sd120;  // Expect 120
        in_data[4] = -32'sd128; // Expect -128
        in_data[5] = 32'sd10;   // Expect 10
        in_data[6] = 32'sd25;   // Expect 25
        in_data[7] = -32'sd90;  // Expect -90
        #10;

        // --- TEST CASE 2: Overflow Values (Clamping Check) ---
        in_data[0] = 32'sd500;   // Upper Overflow  -> Expect 127
        in_data[1] = -32'sd1000; // Lower Overflow  -> Expect -128
        in_data[2] = 32'sd3000;  // Upper Overflow  -> Expect 127
        in_data[3] = -32'sd500;  // Lower Overflow  -> Expect -128
        in_data[4] = 32'sd127;   // Boundary High   -> Expect 127
        in_data[5] = -32'sd129;  // Boundary Low    -> Expect -128
        in_data[6] = 32'sd80;    // Normal          -> Expect 80
        in_data[7] = 32'sd0;     // Zero            -> Expect 0
        #10;

        in_valid = 0;
        #40; // Allow pipeline stages to flush out

        $display("\n>> Quantizer Simulation Complete <<");
        $finish;
    end

    // Monitor Output Pipeline
    always @(posedge clk) begin
        if (out_valid) begin
            #1;
            $display("[QUANT OUTPUT @ t=%0t] out_data = [%0d, %0d, %0d, %0d, %0d, %0d, %0d, %0d]", 
                     $time, out_data[0], out_data[1], out_data[2], out_data[3], 
                            out_data[4], out_data[5], out_data[6], out_data[7]);
        end
    end

endmodule