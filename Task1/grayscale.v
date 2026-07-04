module grayscale (
    input  [23:0] pixel_in,
    output [7:0]  gray_out
);
    wire [7:0] r = pixel_in[23:16];
    wire [7:0] g = pixel_in[15:8];
    wire [7:0] b = pixel_in[7:0];

    assign gray_out = (77*r + 150*g + 29*b) >> 8;
endmodule