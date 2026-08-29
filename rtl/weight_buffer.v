`timescale 1ns / 1ps

module weight_buffer #(
    parameter DATA_WIDTH = 8,
    parameter ARRAY_SIZE = 8,
    parameter ADDR_WIDTH = 10
)(
    input clk,
    input rst,

    input we_A,
    input [ADDR_WIDTH-1:0] addr_A,
    input signed [(DATA_WIDTH*ARRAY_SIZE)-1:0] din_A,

    input ena_B,
    input [ADDR_WIDTH-1:0] addr_B,
    output reg signed [(DATA_WIDTH*ARRAY_SIZE)-1:0] dout_B
);

    localparam WORD_WIDTH = DATA_WIDTH * ARRAY_SIZE;
    localparam DEPTH = (1 << ADDR_WIDTH);

    (* ram_style = "block" *)
    reg signed [WORD_WIDTH-1:0] ram [0:DEPTH-1];

    always @(posedge clk) begin
        if (we_A) begin
            ram[addr_A] <= din_A;
        end
    end

    always @(posedge clk) begin
        if (ena_B) begin
            dout_B <= ram[addr_B];
        end
    end

endmodule