`timescale 1ns / 1ps

module tb_max_pool();

    // -----------------------------------------------------------------
    // Parameters
    // -----------------------------------------------------------------
    localparam WIDTH = 8; // 8x4 image grid

    // -----------------------------------------------------------------
    // Signals
    // -----------------------------------------------------------------
    reg clk;
    reg rst;
    reg signed [7:0] pixel;
    reg signed [7:0] pixel_prev;
    reg valid_in;
    
    wire signed [7:0] pooled;
    wire valid_out;

    // -----------------------------------------------------------------
    // UUT Instantiation
    // -----------------------------------------------------------------
    max_pool #(
        .WIDTH(WIDTH)
    ) uut (
        .clk(clk),
        .rst(rst),
        .pixel(pixel),
        .pixel_prev(pixel_prev),
        .pooled(pooled),
        .valid_in(valid_in),
        .valid_out(valid_out)
    );

    // -----------------------------------------------------------------
    // Clock Generation
    // -----------------------------------------------------------------
    initial begin
        clk = 0;
        forever #5 clk = ~clk; 
    end

    // -----------------------------------------------------------------
    // Test Data Matrices
    // -----------------------------------------------------------------
    reg signed [7:0] img [0:3][0:7];
    reg signed [7:0] expected_pool [0:7];
    
    integer x, y, stall_cycles;
    integer out_idx = 0;
    integer errors = 0;

    initial begin
        // Row 0 & 1: Tests basic positives, all negatives, zeroes, and large leaps
        img[0][0] =  10; img[0][1] =   5; img[0][2] = -10; img[0][3] = -20; img[0][4] =   0; img[0][5] =   0; img[0][6] = 100; img[0][7] =  50;
        img[1][0] =  12; img[1][1] =   6; img[1][2] =  -5; img[1][3] = -15; img[1][4] = -10; img[1][5] =  -5; img[1][6] =  10; img[1][7] =  20;
        
        // Expected Max values for Rows 0 and 1:
        expected_pool[0] = 12;  // max(10, 5, 12, 6)
        expected_pool[1] = -5;  // max(-10, -20, -5, -15) 
        expected_pool[2] = 0;   // max(0, 0, -10, -5)
        expected_pool[3] = 100; // max(100, 50, 10, 20)

        // Row 2 & 3: Tests signed limits (-128 to 127) and max values in different spatial positions
        img[2][0] = 127; img[2][1] =   0; img[2][2] =-128; img[2][3] = 127; img[2][4] =  10; img[2][5] =  20; img[2][6] =  30; img[2][7] =  40;
        img[3][0] =   0; img[3][1] =   1; img[3][2] = 126; img[3][3] =-127; img[3][4] = -50; img[3][5] = -40; img[3][6] = -30; img[3][7] = -20;

        // Expected Max values for Rows 2 and 3:
        expected_pool[4] = 127; // max(127, 0, 0, 1)
        expected_pool[5] = 127; // max(-128, 127, 126, -127)
        expected_pool[6] = 20;  // max(10, 20, -50, -40)
        expected_pool[7] = 40;  // max(30, 40, -30, -20)
    end

    // -----------------------------------------------------------------
    // Stimulus Process (Applied on NEGEDGE to avoid race conditions)
    // -----------------------------------------------------------------
    initial begin
        rst = 1;
        valid_in = 0;
        pixel = 0;
        pixel_prev = 0;

        #20;
        @(negedge clk);
        rst = 0;
        
        $display("Starting Detailed Max Pool Verification...");
        $display("------------------------------------------");

        for (y = 0; y < 4; y = y + 1) begin
            for (x = 0; x < WIDTH; x = x + 1) begin
                
                // Randomly stall the pipeline safely
                stall_cycles = $urandom_range(0, 2); 
                if (stall_cycles > 0) begin
                    valid_in = 0;
                    repeat(stall_cycles) @(negedge clk);
                end

                // Setup the pixel data
                valid_in = 1;
                pixel = img[y][x];
                if (y == 0) begin
                    pixel_prev = 8'd0; 
                end else begin
                    pixel_prev = img[y-1][x];
                end
                
                // Wait one clock cycle for the module to capture it on the posedge
                @(negedge clk);
            end
        end

        // Pipeline flush
        valid_in = 1;
        pixel = 8'd0;
        pixel_prev = 8'd0;
        @(negedge clk);
        
        valid_in = 0;

        // Wait for final processing
        #50;
        
        $display("------------------------------------------");
        if (errors == 0 && out_idx == 8) begin
            $display("TEST PASSED: All %0d pooled values matched expected results.", out_idx);
        end else begin
            $display("TEST FAILED: %0d errors found, %0d outputs generated.", errors, out_idx);
        end
        
        $finish;
    end

    // -----------------------------------------------------------------
    // Output Checker Monitor (Checked on NEGEDGE)
    // -----------------------------------------------------------------
    always @(negedge clk) begin
        if (valid_out) begin
            if (out_idx < 8) begin
                if (pooled === expected_pool[out_idx]) begin
                    $display("Time: %0t | PASS | Window %0d | Expected: %4d | Got: %4d", 
                             $time, out_idx, expected_pool[out_idx], pooled);
                end else begin
                    $display("Time: %0t | FAIL | Window %0d | Expected: %4d | Got: %4d", 
                             $time, out_idx, expected_pool[out_idx], pooled);
                    errors = errors + 1;
                end
            end else begin
                $display("Time: %0t | FAIL | Unexpected extra valid_out triggered! Got: %4d", $time, pooled);
                errors = errors + 1;
            end
            
            out_idx = out_idx + 1;
        end
    end

endmodule