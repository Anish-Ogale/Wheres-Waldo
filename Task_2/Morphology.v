module Morphology #(
    parameter WIDTH = 256,            
    parameter DELAY = 2*WIDTH + 4       
    input  wire       clk,
    input  wire       rst,
    input  wire       valid_in,
    input  wire [7:0] pixel_in,
    output wire       valid_out,
    output reg  [7:0] pixel_out
);

   
    reg [7:0] linebuf1 [0:WIDTH-1];  
    reg [7:0] linebuf2 [0:WIDTH-1];   
    reg [8:0] col_ptr;                

    wire [7:0] row1_pixel = linebuf1[col_ptr];   
    wire [7:0] row2_pixel = linebuf2[col_ptr];  

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            col_ptr <= 0;
        end else if (valid_in) begin
            linebuf2[col_ptr] <= linebuf1[col_ptr];  
            linebuf1[col_ptr] <= pixel_in;           
            col_ptr <= (col_ptr == WIDTH-1) ? 0 : col_ptr + 1;
        end
    end

    reg [7:0] row0_sr [0:2];  
    reg [7:0] row1_sr [0:2];  
    reg [7:0] row2_sr [0:2]; 

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            row0_sr[0]<=0; row0_sr[1]<=0; row0_sr[2]<=0;
            row1_sr[0]<=0; row1_sr[1]<=0; row1_sr[2]<=0;
            row2_sr[0]<=0; row2_sr[1]<=0; row2_sr[2]<=0;
        end else if (valid_in) begin
            row0_sr[2]<=row0_sr[1]; row0_sr[1]<=row0_sr[0]; row0_sr[0]<=pixel_in;
            row1_sr[2]<=row1_sr[1]; row1_sr[1]<=row1_sr[0]; row1_sr[0]<=row1_pixel;
            row2_sr[2]<=row2_sr[1]; row2_sr[1]<=row2_sr[0]; row2_sr[0]<=row2_pixel;
        end
    end

    function [7:0] min2(input [7:0] a, input [7:0] b);
        min2 = (a < b) ? a : b;
    endfunction

    function [7:0] max2(input [7:0] a, input [7:0] b);
        max2 = (a > b) ? a : b;
    endfunction

    wire [7:0] erosion_comb  = min2(row0_sr[0], min2(row0_sr[1], min2(row0_sr[2],
                                 min2(row1_sr[0], min2(row1_sr[1], min2(row1_sr[2],
                                 min2(row2_sr[0], min2(row2_sr[1], row2_sr[2]))))))));

    wire [7:0] dilation_comb = max2(row0_sr[0], max2(row0_sr[1], max2(row0_sr[2],
                                 max2(row1_sr[0], max2(row1_sr[1], max2(row1_sr[2],
                                 max2(row2_sr[0], max2(row2_sr[1], row2_sr[2]))))))));

    reg [7:0] erosion_out;
    reg [7:0] dilation_out;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            erosion_out  <= 0;
            dilation_out <= 0;
            pixel_out    <= 0;
        end else begin
            erosion_out  <= erosion_comb;                   
            dilation_out <= dilation_comb;                  
            pixel_out    <= dilation_comb - erosion_comb;   
        end
    end

    reg [10:0] delay_cnt;
    always @(posedge clk or posedge rst) begin
        if (rst) delay_cnt <= 0;
        else if (valid_in && delay_cnt < DELAY) delay_cnt <= delay_cnt + 1;
    end
    assign valid_out = (delay_cnt >= DELAY);

endmodule