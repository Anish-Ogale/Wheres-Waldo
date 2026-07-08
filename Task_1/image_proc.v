module image_proc (
    input  [23:0] pixel_in,
    output [7:0]  pixel_out
);
    wire [7:0] r = pixel_in[23:16];
    wire [7:0] g = pixel_in[15:8];
    wire [7:0] b = pixel_in[7:0];

    // Stage 1: grayscale                                  
    wire [7:0] gray = (77*r + 150*g + 29*b) >> 8;

    // Stage 2: invert the grayscale result                
    assign pixel_out = 8'd255 - gray;

endmodule