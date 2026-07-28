`timescale 1ns / 1ps


module Leaky_ReLU (
            
      input clk,
      
  input signed [31:0] deskewed [0:7],
      output reg signed [31:0] leaked [0:7] 
            
            
            
            
    );
  
  
    
    
  localparam signed [31:0]  a = 32'sd26;
  
  
  reg signed [63:0] multiplied [0:7];
  reg signed [31:0] mul_trunc[0:7];
  
  
  always @(*) begin
    for(int i=0;i<8;i++)  begin
      multiplied[i] = deskewed[i]*a;
      mul_trunc[i] = multiplied[i][39:8];
    end
  end
  
  
  always @(posedge clk) begin
    for(int i=0;i<8;i++) begin
      if(deskewed[i] <0) begin
        leaked[i] <= mul_trunc[i];
      end else begin
        leaked[i] <= deskewed[i];
        
    end
    end
  end
   
endmodule

