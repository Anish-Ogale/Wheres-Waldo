`timescale 1ns / 1ps

module Leaky_ReLU (
      input clk,
      input signed [255:0] deskewed_flat,
      output reg signed [255:0] leaked_flat
    );

  localparam signed [31:0] a = 32'sd26;

  reg signed [63:0] multiplied [0:7];
  reg signed [31:0] mul_trunc [0:7];
  reg signed [31:0] deskewed [0:7];
    
  integer i;

  always @(*) begin
    for(i = 0; i < 8; i = i + 1) begin
      deskewed[i] = deskewed_flat[i*32 +: 32];
      multiplied[i] = deskewed[i] * a;
      mul_trunc[i] = multiplied[i][39:8];
    end
  end

  always @(posedge clk) begin
    for(i = 0; i < 8; i = i + 1) begin
      if(deskewed[i] < 0) begin
        leaked_flat[i*32 +: 32] <= mul_trunc[i];
      end else begin
        leaked_flat[i*32 +: 32] <= deskewed[i];
      end
    end
  end
   
endmodule