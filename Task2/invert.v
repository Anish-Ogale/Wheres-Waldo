module invert (
    input  [23:0] pixel_in,
    output [23:0] pixel_out
);
    wire [7:0] r = pixel_in[23:16];
    wire [7:0] g = pixel_in[15:8];
    wire [7:0] b = pixel_in[7:0];

    assign pixel_out = {8'd255 - r, 8'd255 - g, 8'd255 - b};
endmodule