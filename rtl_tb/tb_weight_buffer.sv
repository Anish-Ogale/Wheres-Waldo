`timescale 1ns / 1ps

module tb_weight_buffer;

    parameter int DATA_WIDTH = 8;
    parameter int ARRAY_SIZE = 8;
    parameter int ADDR_WIDTH = 10;

    logic clk;
    logic rst_n;
    logic we_A;
    logic [ADDR_WIDTH-1:0] addr_A;
    logic [(DATA_WIDTH*ARRAY_SIZE)-1:0] din_A;
    logic ena_B;
    logic [ADDR_WIDTH-1:0] addr_B;
    logic signed [DATA_WIDTH-1:0] dout_B [0:ARRAY_SIZE-1];

    // Instantiate Unit Under Test (UUT)
    weight_buffer #(
        .DATA_WIDTH(DATA_WIDTH),
        .ARRAY_SIZE(ARRAY_SIZE),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) uut (
        .clk(clk),
        .rst_n(rst_n),
        .we_A(we_A),
        .addr_A(addr_A),
        .din_A(din_A),
        .ena_B(ena_B),
        .addr_B(addr_B),
        .dout_B(dout_B)
    );

    // 100 MHz Clock Generation
    always #5 clk = ~clk;

    initial begin
        // Initialize
        clk    = 0;
        rst_n  = 0;
        we_A   = 0;
        addr_A = 0;
        din_A  = 0;
        ena_B  = 0;
        addr_B = 0;

        #20 rst_n = 1;
        #10;

        // --- WRITE PHASE ---
        // Write Word 0: {8'h08, 8'h07, 8'h06, 8'h05, 8'h04, 8'h03, 8'h02, 8'h01}
        we_A   = 1;
        addr_A = 10'd0;
        din_A  = 64'h0807060504030201;
        #10;

        // Write Word 1: {-8'd1, -8'd2, -8'd3, -8'd4, 8'd10, 8'd20, 8'd30, 8'd40}
        addr_A = 10'd1;
        din_A  = {8'sd10, 8'sd20, 8'sd30, 8'sd40, -8'sd10, -8'sd20, -8'sd30, -8'sd40};
        #10;
        we_A   = 0;
        #20;

        // --- READ PHASE ---
        // Read Address 0
        ena_B  = 1;
        addr_B = 10'd0;
        #10; // Wait for BRAM read latency

        // Read Address 1
        addr_B = 10'd1;
        #10;

        ena_B  = 0;
        #20;

        $display(">> Weight Buffer Simulation Complete <<");
        $finish;
    end

    // Monitor Outputs
    always @(posedge clk) begin
        if (ena_B) begin
            #1; // Sample right after clock edge
            $display("[READ @ t=%0t] Addr=%0d | dout_B = [%0d, %0d, %0d, %0d, %0d, %0d, %0d, %0d]", 
                     $time, addr_B, dout_B[0], dout_B[1], dout_B[2], dout_B[3], 
                                    dout_B[4], dout_B[5], dout_B[6], dout_B[7]);
        end
    end

endmodule