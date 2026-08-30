`timescale 1ns / 1ps

module calculation_block #(
    parameter size = 8
)(
    input clk,
    input rst,
    input [3:0] layer_count,
    input [7:0] in_tile,
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

    reg [10:0] channel_in;
    reg [(8*size)-1:0] masked_pixel;

    always @(*) begin
        case(layer_count)
            4'd0: channel_in = 11'd3;
            4'd1: channel_in = 11'd16;
            4'd2: channel_in = 11'd32;
            4'd3: channel_in = 11'd64;
            4'd4: channel_in = 11'd128;
            4'd5: channel_in = 11'd256;
            4'd6: channel_in = 11'd512;
            4'd7: channel_in = 11'd1024;
            4'd8: channel_in = 11'd1024;
            default: channel_in = 11'd0;
        endcase
        
        masked_pixel = pixel_in;
        if (in_tile == (channel_in - 1) / 8) begin
            case (channel_in % 8)
                1: masked_pixel[63:8] = 56'd0;
                2: masked_pixel[63:16] = 48'd0;
                3: masked_pixel[63:24] = 40'd0;
                4: masked_pixel[63:32] = 32'd0;
                5: masked_pixel[63:40] = 24'd0;
                6: masked_pixel[63:48] = 16'd0;
                7: masked_pixel[63:56] = 8'd0;
                0: ; 
            endcase
        end
    end

    skewer #(
        .size(size)
    ) skewer_inst (
        .clk(clk),
        .pixel_in(masked_pixel),
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
