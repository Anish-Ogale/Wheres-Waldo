module example (
  input [7:0] pixel_in,
  output [7:0] pixel_out
		
);
  assign pixel_out = 8'hff-pixel_in;
endmodule
