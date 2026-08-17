`timescale 1ns / 1ps

module MAC_tb();

    // 1. Declare signals for driving the Unit Under Test (UUT)
    reg signed [7:0] num1;
    reg signed [7:0] num2;
    reg clk;
    reg rst;
    wire signed [31:0] sum;

    // 2. Instantiate the MAC module
    MAC uut (
        .num1(num1),
        .num2(num2),
        .clk(clk),
        .rst(rst),
        .sum(sum)
    );

    // 3. Generate a 100 MHz clock (10ns period)
    always #5 clk = ~clk;

    // 4. Test Stimulus Process
    initial begin
        // Initialize inputs
        clk  = 0;
        rst  = 1;
        num1 = 0;
        num2 = 0;

        // Display header in console
        $display("--------------------------------------------------");
        $display("   Time | rst | num1 | num2 |     sum    | Expected");
        $display("--------------------------------------------------");

        // Hold reset for 2 clock cycles
        #20;
        rst = 0;

        // --------------------------------------------------
        // Test Case 1: Positive numbers accumulation
        // --------------------------------------------------
        // Cycle 1: 5 * 4 = 20  --> Accumulator = 20
        @(posedge clk);
        num1 = 8'sd5; 
        num2 = 8'sd4;

        // Cycle 2: 10 * 2 = 20 --> Accumulator = 20 + 20 = 40
        @(posedge clk);
        num1 = 8'sd10; 
        num2 = 8'sd2;

        // Cycle 3: 3 * 3 = 9   --> Accumulator = 40 + 9 = 49
        @(posedge clk);
        num1 = 8'sd3; 
        num2 = 8'sd3;

        // --------------------------------------------------
        // Test Case 2: Signed (negative) numbers
        // --------------------------------------------------
        // Cycle 4: (-6) * 5 = -30 --> Accumulator = 49 + (-30) = 19
        @(posedge clk);
        num1 = -8'sd6; 
        num2 = 8'sd5;

        // Cycle 5: (-4) * (-3) = +12 --> Accumulator = 19 + 12 = 31
        @(posedge clk);
        num1 = -8'sd4; 
        num2 = -8'sd3;

        // Wait one clock cycle to capture final math
        @(posedge clk);
        num1 = 8'sd0;
        num2 = 8'sd0;

        // Check Case 1 & 2 result
        #1; // Brief delay to sample stable sum
        if (sum === 32'sd31) begin
            $display("[PASS] Accumulation correctly reached 31");
        end else begin
            $display("[FAIL] Expected 31, got %d", sum);
        end

        // --------------------------------------------------
        // Test Case 3: Reset functionality
        // --------------------------------------------------
        @(posedge clk);
        rst = 1;

        #1;
        if (sum === 32'sd0) begin
            $display("[PASS] Reset successfully cleared accumulator to 0");
        end else begin
            $display("[FAIL] Reset failed, got %d", sum);
        end

        // Finish simulation
        #20;
        $display("--------------------------------------------------");
        $display("Simulation Complete.");
        $finish;
    end

    // Monitor process to print signal state whenever inputs or outputs change
    always @(posedge clk) begin
        #1; // Delay slightly past posedge to print updated registers
        $display("%7t |  %b  | %4d | %4d | %10d |", $time, rst, num1, num2, sum);
    end

endmodule
