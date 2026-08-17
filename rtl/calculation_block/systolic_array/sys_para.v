`timescale 1ns / 1ps

module sys_para #(
    parameter size = 8
)(
    input clk,
    input rst,
    input signed [(8*size)-1:0] weight,
    input signed [(8*size)-1:0] pixel,
    output signed [(32*size)-1:0] sum,
    input load_en
);

    wire signed [31:0] sum_temp [0:size-1][0:size-1];
    wire signed [7:0] weight_temp [0:size-1][0:size-1];
    wire signed [7:0] pixel_temp [0:size-1][0:size-1];

    genvar i;
    genvar j;

    generate
        for (i = 0; i < size; i = i + 1) begin : row
            for (j = 0; j < size; j = j + 1) begin : column

                MAC #(
                    .pixel_width(8),
                    .sum_width(32),
                    .weight_width(8)
                ) M (
                    .clk(clk),
                    .rst(rst),
                    .pixel_in(
                        (j == 0) ?
                        pixel[(i*8) +: 8] :
                        pixel_temp[i][j-1]
                    ),
                    .sum_in(
                        (i == 0) ?
                        32'sd0 :
                        sum_temp[i-1][j]
                    ),
                    .weight(
                        (i == 0) ?
                        weight[(j*8) +: 8] :
                        weight_temp[i-1][j]
                    ),
                    .sum_out(sum_temp[i][j]),
                    .pixel_out(pixel_temp[i][j]),
                    .load_en(load_en),
                    .weight_out(weight_temp[i][j])
                );

                if (i == size-1) begin : output_assign
                    assign sum[(j*32) +: 32] = sum_temp[i][j];
                end

            end
        end
    endgenerate

endmodule