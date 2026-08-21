`timescale 1ns / 1ps

module calculation_block #(
    parameter size = 8
)(
    input clk,
    input rst,
    input signed [(8*size)-1:0] pixel_in,
    input signed [(8*size)-1:0] weight_in,
    input load_en,
    output signed [(32*size)-1:0] sum_out
);

    wire signed [(8*size)-1:0] skewed_pixel;
    wire signed [(32*size)-1:0] raw_sum;

    skewer #(
        .size(size)
    ) skewer_inst (
        .clk(clk),
        .pixel_in(pixel_in),
        .pixel_out(skewed_pixel)
    );

    sys_para #(
        .size(size)
    ) systolic_array_inst (
        .clk(clk),
        .rst(rst),
        .weight(weight_in),
        .pixel(skewed_pixel),
        .sum(raw_sum),
        .load_en(load_en)
    );

    deskewer #(
        .size(size)
    ) deskewer_inst (
        .clk(clk),
        .pixel_in(raw_sum),
        .pixel_out(sum_out)
    );

endmodule