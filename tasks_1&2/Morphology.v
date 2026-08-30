// ============================================================================ 
// MODULE: Morphology 
// PURPOSE: Image morphology operations (Erosion & Dilation) for YOLO detection 
// DESCRIPTION: Processes video pixels to find edges by computing the difference 
//              between dilation (maximum) and erosion (minimum) in a 3x3 grid. 
//              This highlights features needed for object detection. 
// ============================================================================ 

module Morphology #( 
    parameter WIDTH = 32,            // Image width in pixels
    parameter DELAY = 2*WIDTH + 4     // Clock cycles to wait before valid output
) (
    input  wire       clk,            // Clock signal
    input  wire       rst,            // Reset signal
    input  wire       valid_in,       // Handshake signal - indicates new pixel data
    input  wire [7:0] pixel_in,       // Input pixel brightness value
    output wire       valid_out,      // Output valid signal
    output reg  [7:0] pixel_out       // Output pixel (Morphological Gradient)
);

    // ======================================================================== 
    // LINE BUFFERS (Synchronous for BRAM Inference)
    // ======================================================================== 
    // We need two lines to form the top, middle, and bottom rows of a 3x3 grid
    reg [7:0] linebuf1 [0:WIDTH-1];   
    reg [7:0] linebuf2 [0:WIDTH-1];   
     
    reg [8:0] col_ptr;                  

    // CHANGE 2: Registered outputs for BRAM inference and a delayed input
    // to match the 1-cycle BRAM read latency.
    reg [7:0] row1_pixel;
    reg [7:0] row2_pixel;
    reg [7:0] delayed_pixel_in;
    reg       valid_in_d1; // Delayed valid signal to drive the shift registers

    always @(posedge clk or posedge rst) begin 
        if (rst) begin 
            col_ptr <= 0;
            valid_in_d1 <= 0;
            delayed_pixel_in <= 0;
            row1_pixel <= 0;
            row2_pixel <= 0;
        end else begin 
            // Delay the valid signal to sync with the BRAM read latency
            valid_in_d1 <= valid_in;
            
            if (valid_in) begin
                // Synchronous read (Vivado will now infer efficient Block RAM)
                row1_pixel <= linebuf1[col_ptr];
                row2_pixel <= linebuf2[col_ptr];

                // Synchronous write: Move old data down, load new pixel in
                linebuf2[col_ptr] <= linebuf1[col_ptr];
                linebuf1[col_ptr] <= pixel_in;
                
                // Delay the newest pixel so it enters the shift registers 
                // on the exact same cycle as the BRAM read data
                delayed_pixel_in <= pixel_in;
                 
                // Advance pointer
                col_ptr <= (col_ptr == WIDTH-1) ? 0 : col_ptr + 1; 
            end 
        end 
    end 

    // ======================================================================== 
    // SHIFT REGISTERS - Build a 3x3 pixel grid
    // ======================================================================== 
    reg [7:0] row0_sr [0:2]; 
    reg [7:0] row1_sr [0:2]; 
    reg [7:0] row2_sr [0:2];  

    always @(posedge clk or posedge rst) begin 
        if (rst) begin 
            row0_sr[0]<=0; row0_sr[1]<=0; row0_sr[2]<=0; 
            row1_sr[0]<=0; row1_sr[1]<=0; row1_sr[2]<=0; 
            row2_sr[0]<=0; row2_sr[1]<=0; row2_sr[2]<=0; 
        end else if (valid_in_d1) begin 
            // Shift using the delayed pixel and synchronous BRAM outputs
            row0_sr[2]<=row0_sr[1]; row0_sr[1]<=row0_sr[0]; row0_sr[0]<=delayed_pixel_in; 
            row1_sr[2]<=row1_sr[1]; row1_sr[1]<=row1_sr[0]; row1_sr[0]<=row1_pixel; 
            row2_sr[2]<=row2_sr[1]; row2_sr[1]<=row2_sr[0]; row2_sr[0]<=row2_pixel; 
        end 
    end 

    // ======================================================================== 
    // HELPER FUNCTIONS
    // ======================================================================== 
    function [7:0] min2(input [7:0] a, input [7:0] b); 
        min2 = (a < b) ? a : b; 
    endfunction 

    function [7:0] max2(input [7:0] a, input [7:0] b); 
        max2 = (a > b) ? a : b; 
    endfunction 

    // ======================================================================== 
    // COMBINATIONAL MIN/MAX TREES
    // ======================================================================== 
    wire [7:0] erosion_comb  = min2(row0_sr[0], min2(row0_sr[1], min2(row0_sr[2], 
                               min2(row1_sr[0], min2(row1_sr[1], min2(row1_sr[2], 
                               min2(row2_sr[0], min2(row2_sr[1], row2_sr[2])))))))); 

    wire [7:0] dilation_comb = max2(row0_sr[0], max2(row0_sr[1], max2(row0_sr[2], 
                               max2(row1_sr[0], max2(row1_sr[1], max2(row1_sr[2], 
                               max2(row2_sr[0], max2(row2_sr[1], row2_sr[2])))))))); 

    // ======================================================================== 
    // OUTPUT PIPELINE STAGE & BOUNDARY HANDLING
    // ======================================================================== 
    reg [7:0] erosion_out; 
    reg [7:0] dilation_out; 

    always @(posedge clk or posedge rst) begin 
        if (rst) begin 
            erosion_out  <= 0; 
            dilation_out <= 0; 
            pixel_out    <= 0; 
        end else if (valid_in_d1) begin 
            // Register combinational results
            erosion_out  <= erosion_comb; 
            dilation_out <= dilation_comb; 
             
            // CHANGE 3 & 4: Use registered values for math, and mask boundaries.
            // If the column pointer is near an edge, force the pixel to 0 (black)
            // to prevent wrap-around visual artifacts.
            if (col_ptr <= 2 || col_ptr >= WIDTH - 1) begin
                pixel_out <= 8'b0;
            end else begin
                // Gradient = Registered Dilation - Registered Erosion
                pixel_out <= dilation_out - erosion_out; 
            end
        end 
    end 

    // ======================================================================== 
    // TIMING SYNCHRONIZATION
    // ======================================================================== 
    reg [10:0] delay_cnt; 
     
    always @(posedge clk or posedge rst) begin 
        if (rst) begin 
            delay_cnt <= 0; 
        end else if (valid_in && delay_cnt < DELAY) begin 
            delay_cnt <= delay_cnt + 1; 
        end 
    end 
     
    // CHANGE 1: valid_out is now tied to valid_in to prevent outputting
    // garbage data continuously during UART idle time.
    assign valid_out = (delay_cnt >= DELAY) && valid_in; 

endmodule