`timescale 1ns / 1ps


module MAC #(

    parameter pixel_width=8,
    parameter sum_width = 32,
    parameter weight_width = 8
    

)(
  
    input clk,
    input rst,
  input signed [pixel_width-1:0] pixel_in,
  input signed [sum_width-1:0] sum_in,
  input signed [weight_width-1:0] weight,
  output reg signed [sum_width-1:0] sum_out,
  output  reg signed [pixel_width-1:0] pixel_out
  
          
    );


    
    always @(posedge clk) begin
    if(rst) begin
        
          
          pixel_out <= '0;
          sum_out <=  '0;
        
    
    
    end else begin
        
      
      
      pixel_out <= pixel_in;
      sum_out <= sum_in + (pixel_in*weight);
    end
    end
  
    endmodule

    
