`timescale 1ns / 1ps
module linebuf#(
parameter width = 416

)(
    input clk,
      input rst,
  input signed [7:0] pixel,
    output reg signed [7:0] pixel_prev,
    input buf_en

);
  
  reg signed [7:0] buffer[0:width-1];
reg [10:0] col_ptr;
                       
  
  
                          always @(posedge clk) begin
                            if(rst) begin
                              col_ptr<= 10'd0;
                            end else begin
                            if(buf_en) begin
                              pixel_prev <= buffer[col_ptr];
                              buffer[col_ptr] <= pixel;
                              
                              if(col_ptr == (width-1)) begin
                                col_ptr <= 10'd0;
                              end else begin
                                col_ptr <= col_ptr + 1'b1;
                              end
                            end
                            end
                          end
  
  
  
  endmodule
