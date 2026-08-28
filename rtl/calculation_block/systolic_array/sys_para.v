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

                wire signed [7:0] p_in;
                wire signed [31:0] s_in;
                wire signed [7:0] w_in;

                if (j == 0) begin : gen_p0
                    assign p_in = pixel[(i*8) +: 8];
                end else begin : gen_pn
                    assign p_in = pixel_temp[i][j-1];
                end

                if (i == 0) begin : gen_sw0
                    assign s_in = 32'sd0;
                    assign w_in = weight[(j*8) +: 8];
                end else begin : gen_swn
                    assign s_in = sum_temp[i-1][j];
                    assign w_in = weight_temp[i-1][j];
                end

                MAC #(
                    .pixel_width(8),
                    .sum_width(32),
                    .weight_width(8)
                ) M (
                    .clk(clk),
                    .rst(rst),
                    .pixel_in(p_in),
                    .sum_in(s_in),
                    .weight(w_in),
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