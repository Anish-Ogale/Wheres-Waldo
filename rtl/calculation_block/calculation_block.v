`timescale 1ns / 1ps

module calculation_block #(
    parameter size = 8
)(
    input clk,
    input rst,
    input signed [(8*size)-1:0] pixel_in,
    input signed [(8*size)-1:0] weight_in,
    input load_en,
    input padding,
    output signed [(32*size)-1:0] sum_out,
    input valid_in,
    input [8:0] addr_in,
    input first_in,
    input last_in,
    output valid_out,
    output [8:0] addr_out,
    output first_out,
    output last_out
);

    wire signed [(8*size)-1:0] skewed_pixel;
    wire signed [(32*size)-1:0] raw_sum;

    skewer #(
        .size(size)
    ) skewer_inst (
        .clk(clk),
        .pixel_in(pixel_in),
        .padding(padding),
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

   
    reg [14:0] valid_pipe, first_pipe, last_pipe;
    reg [8:0] addr_pipe [0:14];
    integer tag_i;
    always @(posedge clk) begin
        if (rst) begin
            valid_pipe <= 15'd0;
            first_pipe <= 15'd0;
            last_pipe  <= 15'd0;
            for (tag_i = 0; tag_i < 15; tag_i = tag_i + 1)
                addr_pipe[tag_i] <= 9'd0;
        end else begin
            valid_pipe[0] <= valid_in;
            first_pipe[0] <= first_in;
            last_pipe[0]  <= last_in;
            addr_pipe[0]  <= addr_in;
            for (tag_i = 1; tag_i < 15; tag_i = tag_i + 1) begin
                valid_pipe[tag_i] <= valid_pipe[tag_i-1];
                first_pipe[tag_i] <= first_pipe[tag_i-1];
                last_pipe[tag_i]  <= last_pipe[tag_i-1];
                addr_pipe[tag_i]  <= addr_pipe[tag_i-1];
            end
        end
    end

    assign valid_out = valid_pipe[14];
    assign addr_out  = addr_pipe[14];
    assign first_out = first_pipe[14];
    assign last_out  = last_pipe[14];

endmodule
