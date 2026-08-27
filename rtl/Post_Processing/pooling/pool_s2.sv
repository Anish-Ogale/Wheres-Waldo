`timescale 1ns / 1ps


module pool_s2#(
  parameter WIDTH = 16


)(
        input clk,
  
  
  
        input rst,
        input tile_start,
        input [4:0] tile_width,
        input signed [7:0] pixel, // Bottom Right 
        input signed [7:0] pixel_prev, // Top Right
        
  output reg signed [7:0] pooled,
  
  input valid_in,
  output reg valid_out
        
        
        
    );
    
    
    reg signed [7:0] pixel_del ; // Bottom Left;
    reg signed [7:0] pixel_prev_del ; // Top Left;
    reg stage2_en;
    
    always @(posedge clk) begin
    if(rst || tile_start) begin
        pixel_del <= 8'd0;
        pixel_prev_del <= 8'd0;
    end else if(valid_in) begin
        pixel_del <= pixel;
        pixel_prev_del <= pixel_prev;
       
        end
        end
  
  reg signed [7:0] max_top;
  reg signed [7:0] max_bottom;
  
  reg [9:0] count_x;
  reg [9:0] count_y;
  
  
  
  
  always @(posedge clk) begin
    if(rst || tile_start) begin      // reset condition
      count_x <= '0;
      count_y <= '0;
      stage2_en <= 1'b0;
      valid_out <= 1'b0;
      max_top <= 8'd0;
      max_bottom <= 8'd0;
    end else begin
      
      stage2_en <= 1'b0;
      valid_out <= 1'b0;
      
      if(valid_in) begin
      
      
      if(count_x == tile_width-1) begin // column counter
        count_x <= '0;
      end else begin
        count_x <= count_x +1'b1;
      end
      
      if(count_x == tile_width-1) begin
        if(count_y ==tile_width-1) begin
            count_y <= '0;
            end else begin
            count_y <= count_y +1'b1;
            end
            end     
      
      if((count_x[0]==1'b1)&&(count_y[0]==1'b1)) begin    // comparator layers
        max_top <= (pixel_prev>pixel_prev_del)?pixel_prev:pixel_prev_del;
    
           max_bottom <= (pixel>pixel_del)?pixel:pixel_del;
           stage2_en <= 1'b1;
        
        
        
        end
        
        
        end
        
        if(stage2_en) begin
        
            pooled <= (max_top>max_bottom)?max_top:max_bottom;
            valid_out <= 1'b1;
        end
      end
      end
      
     
      
     
    

  
  

    

  
        
      
endmodule
