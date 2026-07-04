module example (
  input [23:0] pixel_in,
  output [7:0] pixel_out
		
);
  wire [9:0] gray_sum;
  wire [17:0] mul;
  wire [7:0] gray;
  assign gray_sum = ({2'b0,pixel_in[7:0]}+{2'b0,pixel_in[15:8]}+{2'b0,pixel_in[23:16]});
   assign mul = gray_sum*8'd85;
  assign gray = mul >> 8;
  assign pixel_out = 8'hff - gray;
  
endmodule