`timescale 1ns / 1ps




module sys_para #(

    parameter size = 8
    
    
)(
    input clk,
    input rst,
    input signed [7:0] weight[0:size-1][0:size-1],
    input signed [7:0] pixel [0:size-1],
    output signed [31:0] sum [0:size-1]
);

    wire signed [31:0] sum_temp [-1:size-1][0:size-1];
    wire signed [7:0] pixel_temp [0:size-1][-1:size-1];

    genvar i,j;

    generate
        for(i=0;i<size;i=i+1) begin : row
            for(j=0;j<size;j=j+1)begin: column
                MAC #(
            .pixel_width(8),  
             .sum_width(32),
            .weight_width(8)
            ) M(
                    .clk(clk),
                    .rst(rst),
                    .pixel_in((j==0) ? pixel[i] : pixel_temp[i][j-1]),
                    .sum_in((i==0) ? 32'd0 : sum_temp[i-1][j]),
                    .weight(weight[i][j]),
                    .sum_out(sum_temp[i][j]),
                    .pixel_out(pixel_temp[i][j])
                );
                if (i == size-1) begin
                    assign sum[j] = sum_temp[i][j];
                end
            end
        end
    endgenerate
endmodule