// ============================================================================
// MODULE: Morphology
// PURPOSE: Image morphology operations (Erosion & Dilation) for YOLO detection
// DESCRIPTION: Processes video pixels to find edges by computing the difference
//              between dilation (maximum) and erosion (minimum) in a 3x3 grid.
//              This highlights features needed for object detection.
// ============================================================================

module Morphology #(
    parameter WIDTH = 256,            // Image width in pixels (256 pixels wide)
    parameter DELAY = 2*WIDTH + 4     // Clock cycles to wait before valid output (516 cycles)
    input  wire       clk,            // Clock signal - synchronizes all operations
    input  wire       rst,            // Reset signal - initializes all registers to 0
    input  wire       valid_in,       // Handshake signal - indicates new pixel data is coming
    input  wire [7:0] pixel_in,       // Input pixel brightness value (0-255)
    output wire       valid_out,      // Output valid signal - indicates result is ready
    output reg  [7:0] pixel_out       // Output pixel - difference between dilation & erosion
);

   
    // ========================================================================
    // LINE BUFFERS - Store two complete image lines for vertical comparisons
    // ========================================================================
    // linebuf1: Stores 256 pixels from the current input line
    // linebuf2: Stores 256 pixels from the previous line
    // We need two lines to form the top, middle, and bottom rows of our 3x3 grid
    reg [7:0] linebuf1 [0:WIDTH-1];  
    reg [7:0] linebuf2 [0:WIDTH-1];   
    
    // col_ptr: Points to current column position (0-255)
    // As pixels come in sequentially, this tracks which position we're filling
    reg [8:0] col_ptr;                

    // Extract pixels at current column from each line buffer
    // These will be the middle column of our 3x3 grid (left-center-right pattern)
    wire [7:0] row1_pixel = linebuf1[col_ptr];   
    wire [7:0] row2_pixel = linebuf2[col_ptr];  

    // ========================================================================
    // PIXEL SHIFTING LOGIC - Fill line buffers and manage column pointer
    // ========================================================================
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // On reset, point to the first pixel position
            col_ptr <= 0;
        end else if (valid_in) begin
            // PIPELINE SHIFT: Move old data down one line
            // linebuf1 (current) → linebuf2 (becomes previous line)
            linebuf2[col_ptr] <= linebuf1[col_ptr];
            
            // NEW PIXEL: Load incoming pixel into current line at this position
            // This is the newest data entering the pipeline
            linebuf1[col_ptr] <= pixel_in;
            
            // ADVANCE POINTER: Move to next pixel position in the image
            // When we reach the end of a line (255), wrap back to start (0)
            col_ptr <= (col_ptr == WIDTH-1) ? 0 : col_ptr + 1;
        end
    end

    // ========================================================================
    // SHIFT REGISTERS - Build a 3x3 pixel grid for morphology operations
    // ========================================================================
    // These three shift registers hold 3 consecutive pixels from each row:
    // [2] = oldest pixel | [1] = middle pixel | [0] = newest pixel
    // This creates a moving window as pixels shift through each clock cycle
    
    // row0_sr: Stores 3 consecutive pixels from the CURRENT input line
    reg [7:0] row0_sr [0:2];
    
    // row1_sr: Stores 3 consecutive pixels from the PREVIOUS line  
    reg [7:0] row1_sr [0:2];
    
    // row2_sr: Stores 3 consecutive pixels from the LINE BEFORE THAT
    reg [7:0] row2_sr [0:2]; 

    // ========================================================================
    // SHIFT REGISTER UPDATE LOGIC - Form the 3x3 grid
    // ========================================================================
    // Visualizing the 3x3 grid formed:
    //    row0_sr[2] | row0_sr[1] | row0_sr[0]  ← current input line
    //    row1_sr[2] | row1_sr[1] | row1_sr[0]  ← previous line
    //    row2_sr[2] | row2_sr[1] | row2_sr[0]  ← line before that
    // 
    // Each cycle: newest value enters [0], [0]→[1]→[2] as others age
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Initialize all shift registers to 0 (black pixels)
            row0_sr[0]<=0; row0_sr[1]<=0; row0_sr[2]<=0;
            row1_sr[0]<=0; row1_sr[1]<=0; row1_sr[2]<=0;
            row2_sr[0]<=0; row2_sr[1]<=0; row2_sr[2]<=0;
        end else if (valid_in) begin
            // SHIFT LEFT for row0: Newest pixel enters at [0], others shift left
            // [2] gets [1], [1] gets [0], [0] gets the new input
            row0_sr[2]<=row0_sr[1]; row0_sr[1]<=row0_sr[0]; row0_sr[0]<=pixel_in;
            
            // SHIFT LEFT for row1: From previous line's linebuf1
            // This creates the middle row of our 3x3 grid
            row1_sr[2]<=row1_sr[1]; row1_sr[1]<=row1_sr[0]; row1_sr[0]<=row1_pixel;
            
            // SHIFT LEFT for row2: From older line's linebuf2
            // This creates the bottom row of our 3x3 grid
            row2_sr[2]<=row2_sr[1]; row2_sr[1]<=row2_sr[0]; row2_sr[0]<=row2_pixel;
        end
    end

    // ========================================================================
    // HELPER FUNCTIONS - Min and Max operations for morphology
    // ========================================================================
    
    // min2: Returns the smaller of two 8-bit values
    // Used for EROSION: shrinks dark areas, expands bright areas
    function [7:0] min2(input [7:0] a, input [7:0] b);
        min2 = (a < b) ? a : b;
    endfunction

    // max2: Returns the larger of two 8-bit values
    // Used for DILATION: shrinks bright areas, expands dark areas
    function [7:0] max2(input [7:0] a, input [7:0] b);
        max2 = (a > b) ? a : b;
    endfunction

    // ========================================================================
    // EROSION COMPUTATION - Find MINIMUM value in 3x3 grid
    // ========================================================================
    // Erosion = min(all 9 pixels in 3x3 grid)
    // This finds the darkest pixel in the neighborhood
    // Effect: Shrinks white regions, grows black regions (edge enhancement)
    // 
    // The nested min2 calls progressively find the minimum:
    // First level: compare horizontal neighbors in each row
    // Second level: compare results from each row
    // Result: Single value = minimum brightness in the 3x3 window
    wire [7:0] erosion_comb  = min2(row0_sr[0], min2(row0_sr[1], min2(row0_sr[2],
                                 min2(row1_sr[0], min2(row1_sr[1], min2(row1_sr[2],
                                 min2(row2_sr[0], min2(row2_sr[1], row2_sr[2]))))))));

    // ========================================================================
    // DILATION COMPUTATION - Find MAXIMUM value in 3x3 grid
    // ========================================================================
    // Dilation = max(all 9 pixels in 3x3 grid)
    // This finds the brightest pixel in the neighborhood
    // Effect: Shrinks black regions, grows white regions (edge enhancement)
    // 
    // The nested max2 calls progressively find the maximum:
    // First level: compare horizontal neighbors in each row
    // Second level: compare results from each row
    // Result: Single value = maximum brightness in the 3x3 window
    wire [7:0] dilation_comb = max2(row0_sr[0], max2(row0_sr[1], max2(row0_sr[2],
                                 max2(row1_sr[0], max2(row1_sr[1], max2(row1_sr[2],
                                 max2(row2_sr[0], max2(row2_sr[1], row2_sr[2]))))))));

    // ========================================================================
    // OUTPUT PIPELINE STAGE - Register the results
    // ========================================================================
    // These intermediate registers hold the erosion and dilation results
    // They add one pipeline stage of latency (needed for timing)
    reg [7:0] erosion_out;
    reg [7:0] dilation_out;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Initialize all output registers to 0
            erosion_out  <= 0;
            dilation_out <= 0;
            pixel_out    <= 0;
        end else begin
            // Register the combinational erosion result
            erosion_out  <= erosion_comb;
            
            // Register the combinational dilation result
            dilation_out <= dilation_comb;
            
            // FINAL OUTPUT: Compute the MORPHOLOGICAL GRADIENT
            // Gradient = Dilation - Erosion
            // This difference highlights EDGES in the image
            // Why: Dilation finds bright edges, Erosion finds dark edges
            // The difference enhances boundaries - perfect for object detection!
            pixel_out    <= dilation_comb - erosion_comb;
        end
    end

    // ========================================================================
    // TIMING SYNCHRONIZATION - Ensure output is valid after pipeline fills
    // ========================================================================
    // The entire pipeline takes time to fill:
    //   - Line buffers need 2 full lines = 2*WIDTH cycles
    //   - Shift registers need 3 pixels = 3 more cycles
    //   - Output register adds 1 more cycle
    //   - Total DELAY = 2*WIDTH + 4 = 516 cycles (for WIDTH=256)
    // 
    // We count from 0 to DELAY, and only assert valid_out when we reach DELAY
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
    
    // Assert valid_out only after pipeline has fully filled
    // This tells downstream modules "the first real morphology result is ready"
    assign valid_out = (delay_cnt >= DELAY);

endmodule
// ============================================================================
// END OF MODULE
// ============================================================================
