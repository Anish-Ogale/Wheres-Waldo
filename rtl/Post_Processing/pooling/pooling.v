`timescale 1ns / 1ps

module pooling#(
  parameter WIDTH = 416
)(
  input clk,
  input rst,
  input signed [7:0] pixel,
  input buf_en,
  input valid_in,
  input pool_select,
  output signed [7:0] pooled,
  output valid_out
);

  wire signed [7:0] pixel_prev;
  wire signed [7:0] pooled_s1;
  wire valid_out_s1;
  wire signed [7:0] pooled_s2;
  wire valid_out_s2;

 
  reg signed [7:0] pixel_align;
  reg valid_in_align;

  always @(posedge clk) begin
    if (rst) begin
      pixel_align <= 8'd0;
      valid_in_align <= 1'b0;
    end else begin
      pixel_align <= pixel;
      valid_in_align <= valid_in;
    end
  end

  linebuf #(
    .width(WIDTH)
  ) u_linebuf (
    .clk(clk),
    .rst(rst),
    .pixel(pixel),
    .pixel_prev(pixel_prev),
    .buf_en(buf_en)
  );

  pool_s1 #(
    .WIDTH(WIDTH)
  ) u_pool_s1 (
    .clk(clk),
    .rst(rst),
    .pixel(pixel_align),       
    .pixel_prev(pixel_prev),
    .pooled(pooled_s1),
    .valid_in(valid_in_align), 
    .valid_out(valid_out_s1)
  );

  pool_s2 #(
    .WIDTH(WIDTH)
  ) u_pool_s2 (
    .clk(clk),
    .rst(rst),
    .pixel(pixel_align),       
    .pixel_prev(pixel_prev),
    .pooled(pooled_s2),
    .valid_in(valid_in_align), 
    .valid_out(valid_out_s2)
  );

  assign pooled = pool_select ? pooled_s2 : pooled_s1;
  assign valid_out = pool_select ? valid_out_s2 : valid_out_s1;

endmodule