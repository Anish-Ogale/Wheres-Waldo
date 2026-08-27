`timescale 1ns / 1ps

module pool_wrapper #(
    parameter WIDTH = 16,
    parameter NUM_CHANNELS = 8
)(
    input clk,
    input rst,
    input tile_start,
    input [4:0] tile_width,
    input signed [63:0] pixel_flat,
    input buf_en,
    input valid_in,
    input pool_select,
    output signed [63:0] pooled_flat,
    output valid_out
);

    wire [NUM_CHANNELS-1:0] valid_out_ch;

    genvar i;
    generate
        for (i = 0; i < NUM_CHANNELS; i = i + 1) begin : POOL_CH
            pooling #(
                .WIDTH(WIDTH)
            ) u_pooling (
                .clk(clk),
                .rst(rst),
                .tile_start(tile_start),
                .tile_width(tile_width),
                .pixel(pixel_flat[i*8 +: 8]),
                .buf_en(buf_en),
                .valid_in(valid_in),
                .pool_select(pool_select),
                .pooled(pooled_flat[i*8 +: 8]),
                .valid_out(valid_out_ch[i])
            );
        end
    endgenerate

    assign valid_out = &valid_out_ch;

endmodule
