`timescale 1ns / 1ps

(* use_dsp = "yes" *)
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
  input load_en,
  
  
  output reg signed [sum_width-1:0] sum_out,
  output signed [weight_width-1:0] weight_out,
  output  reg signed [pixel_width-1:0] pixel_out
  
          
    );
  reg signed [weight_width-1:0] weight_store;

  assign weight_out = weight_store;
    
    always @(posedge clk) begin
      
      
   
        
            if(rst) begin
        
          
          pixel_out <= '0;
          sum_out <=  '0;
          weight_store <= '0;
    
    
            end else begin
            
             if(load_en) begin
        weight_store<= weight;
      end else begin
        
      
      
          pixel_out <= pixel_in;
        sum_out <= sum_in + (pixel_in*weight_store);
        end
        end
    end
  
    endmodule
