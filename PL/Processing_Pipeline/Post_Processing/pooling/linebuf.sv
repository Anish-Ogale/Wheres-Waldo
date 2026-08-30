`timescale 1ns / 1ps
module linebuf#(
parameter width = 16

)(
  input clk,
      input rst,
  input tile_start,
  input [4:0] tile_width,
  input signed [7:0] pixel,
    output reg signed [7:0] pixel_prev,
    input buf_en

);
  
  reg signed [7:0] buffer[0:width-1];
reg [10:0] col_ptr;
                       
  
  
                          always @(posedge clk) begin
                            if(rst || tile_start) begin
                              col_ptr<= 10'd0;
                              pixel_prev <= 8'd0;
                            end else begin
                            if(buf_en) begin
                              pixel_prev <= buffer[col_ptr];
                              buffer[col_ptr] <= pixel;
                              
                              if(col_ptr == (tile_width-1)) begin
                                col_ptr <= 10'd0;
                              end else begin
                                col_ptr <= col_ptr + 1'b1;
                              end
                            end
                            end
                          end
  
  
  
  endmodule
