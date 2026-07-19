module Morphology #(
    parameter WIDTH = 256,            // Image width in pixels (256 pixels wide)
    parameter DELAY = 2*WIDTH + 4 // Clock cycles to wait before valid output (516 cycles)
)(
    input  wire       clk,            // Clock signal - synchronizes all operations
    input  wire       rst,            // Reset signal - initializes all registers to 0
    input  wire       valid_in,       // Handshake signal - indicates new pixel data is coming
    input  wire [7:0] pixel_in,       // Input pixel brightness value (0-255)
    output wire       valid_out,      // Output valid signal - indicates result is ready
    output reg  [7:0] pixel_out       // Output pixel - difference between dilation & erosion
);
    reg [7:0] linebuf1 [0:WIDTH-1];  
    reg [7:0] linebuf2 [0:WIDTH-1];   
   
    reg [8:0] col_ptr;                

    wire [7:0] row1_pixel = linebuf1[col_ptr];   
    wire [7:0] row2_pixel = linebuf2[col_ptr];  

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // On reset, point to the first pixel position
            col_ptr <= 0;
        end else if (valid_in) begin
            linebuf2[col_ptr] <= linebuf1[col_ptr];
            linebuf1[col_ptr] <= pixel_in;
            col_ptr <= (col_ptr == WIDTH-1) ? 0 : col_ptr + 1;
        end
    end
    
    // row0_sr: Stores 3 consecutive pixels from the CURRENT input line
    reg [7:0] row0_sr [0:2];
    
    // row1_sr: Stores 3 consecutive pixels from the PREVIOUS line  
    reg [7:0] row1_sr [0:2];
    
    // row2_sr: Stores 3 consecutive pixels from the LINE BEFORE THAT
    reg [7:0] row2_sr [0:2]; 
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Initialize all shift registers to 0 (black pixels)
            row0_sr[0]<=0; row0_sr[1]<=0; row0_sr[2]<=0;
            row1_sr[0]<=0; row1_sr[1]<=0; row1_sr[2]<=0;
            row2_sr[0]<=0; row2_sr[1]<=0; row2_sr[2]<=0;
        end else if (valid_in) begin  
            row0_sr[2]<=row0_sr[1]; row0_sr[1]<=row0_sr[0]; row0_sr[0]<=pixel_in;
            row1_sr[2]<=row1_sr[1]; row1_sr[1]<=row1_sr[0]; row1_sr[0]<=row1_pixel;
            row2_sr[2]<=row2_sr[1]; row2_sr[1]<=row2_sr[0]; row2_sr[0]<=row2_pixel;
        end
    end

    function [7:0] min2(input [7:0] a, input [7:0] b);
        min2 = (a < b) ? a : b;
    endfunction
    
    function [7:0] max2(input [7:0] a, input [7:0] b);
        max2 = (a > b) ? a : b;
    endfunction

    wire [7:0] erosion_comb  = min2(row0_sr[0], min2(row0_sr[1], min2(row0_sr[2],
                                 min2(row1_sr[0], min2(row1_sr[1], min2(row1_sr[2],
                                 min2(row2_sr[0], min2(row2_sr[1], row2_sr[2]))))))));

    wire [7:0] dilation_comb = max2(row0_sr[0], max2(row0_sr[1], max2(row0_sr[2],
                                 max2(row1_sr[0], max2(row1_sr[1], max2(row1_sr[2],
                                 max2(row2_sr[0], max2(row2_sr[1], row2_sr[2]))))))));

    reg [7:0] erosion_out;
    reg [7:0] dilation_out;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Initialize all output registers to 0
            erosion_out  <= 0;
            dilation_out <= 0;
            pixel_out    <= 0;
        end else begin
            erosion_out  <= erosion_comb;
            dilation_out <= dilation_comb;
            pixel_out    <= dilation_comb - erosion_comb;
        end
    end
    
    reg [10:0] delay_cnt;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Initialize delay counter to 0
            delay_cnt <= 0;
        end else if (valid_in && delay_cnt < DELAY) begin
            // Increment counter while input is valid and we haven't reached DELAY yet
            delay_cnt <= delay_cnt + 1;
        end
        // Once delay_cnt >= DELAY, it stops incrementing
    end
    assign valid_out = (delay_cnt >= DELAY);

endmodule
