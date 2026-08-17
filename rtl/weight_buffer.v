`timescale 1ns / 1ps

module weight_buffer #(
    parameter DATA_WIDTH = 8,
    parameter ARRAY_SIZE = 8,
    parameter ADDR_WIDTH = 10
)(
    input clk,
    input rst,

    input we_A,
    input [ADDR_WIDTH:0] addr_A,
    input signed [(DATA_WIDTH*ARRAY_SIZE/2)-1:0] din_A,

    input ena_B,
    input [ADDR_WIDTH-1:0] addr_B,
    output reg signed [(DATA_WIDTH*ARRAY_SIZE)-1:0] dout_B
);

    localparam WORD_WIDTH = DATA_WIDTH * ARRAY_SIZE;
    localparam HALF_WIDTH = WORD_WIDTH / 2;
    localparam DEPTH = (1 << ADDR_WIDTH);

    (* ram_style = "block" *)
    reg signed [WORD_WIDTH-1:0] ram [0:DEPTH-1];

    reg signed [HALF_WIDTH-1:0] wr_pend;
    reg wr_pend_valid;

    always @(posedge clk) begin
        if (rst) begin
            wr_pend_valid <= 1'b0;
        end
        else begin
            if (we_A) begin
                if (addr_A[0] == 1'b0) begin
                    wr_pend       <= din_A;
                    wr_pend_valid <= 1'b1;
                end
                else begin
                    ram[addr_A[ADDR_WIDTH:1]] <= {din_A, wr_pend};
                    wr_pend_valid <= 1'b0;
                end
            end
        end
    end

    always @(posedge clk) begin
        if (ena_B) begin
            dout_B <= ram[addr_B];
        end
    end

endmodule