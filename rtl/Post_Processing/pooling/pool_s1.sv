`timescale 1ns / 1ps

module pool_s1#(
  parameter WIDTH = 416
)(
  input clk,
  input rst,
  input signed [7:0] pixel,
  input signed [7:0] pixel_prev,
  output reg signed [7:0] pooled,
  input valid_in,
  output reg valid_out
);
    
  reg signed [7:0] pixel_del ; 
  reg signed [7:0] pixel_prev_del ; 
  reg stage2_en;
    
  always @(posedge clk) begin
    if(valid_in) begin
      pixel_del <= pixel;
      pixel_prev_del <= pixel_prev;
    end
  end
  
  reg signed [7:0] max_top;
  reg signed [7:0] max_bottom;
  
  reg [9:0] count_x;
  reg [9:0] count_y;
  
  always @(posedge clk) begin
    if(rst) begin      
      count_x <= '0;
      count_y <= '0;
      stage2_en <= 1'b0;
      valid_out <= 1'b0;
    end else begin
      
      stage2_en <= 1'b0;
      valid_out <= 1'b0;
      
      if(valid_in) begin
      
        if(count_x == WIDTH-1) begin 
          count_x <= '0;
        end else begin
          count_x <= count_x + 1'b1;
        end
        
        if(count_x == WIDTH-1) begin
          if(count_y == WIDTH-1) begin
            count_y <= '0;
          end else begin
            count_y <= count_y + 1'b1;
          end
        end     
        
        if((count_x > 0) && (count_y > 0)) begin    
          max_top <= (pixel_prev > pixel_prev_del) ? pixel_prev : pixel_prev_del;
          max_bottom <= (pixel > pixel_del) ? pixel : pixel_del;
          stage2_en <= 1'b1;
        end
        
      end
        
      if(stage2_en) begin
        pooled <= (max_top > max_bottom) ? max_top : max_bottom;
        valid_out <= 1'b1;
      end
    end
  end
      
endmodule