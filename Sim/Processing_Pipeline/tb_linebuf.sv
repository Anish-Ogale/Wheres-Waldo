`timescale 1ns / 1ps

module tb_linebuf();

  // Override the width parameter to a smaller size for easier observation
  parameter TEST_WIDTH = 8;

  // Testbench signals
  reg clk;
  reg rst;
  reg signed [7:0] pixel;
  reg buf_en;
  wire signed [7:0] pixel_prev;

  // Instantiate the Device Under Test (DUT)
  linebuf #(
    .width(TEST_WIDTH)
  ) dut (
    .clk(clk),
    .rst(rst),
    .pixel(pixel),
    .pixel_prev(pixel_prev),
    .buf_en(buf_en)
  );

  // Clock generation: 10ns period (100 MHz)
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  // Stimulus block
  initial begin
    // 1. Initialize signals and assert reset
    rst = 1;
    pixel = 8'd0;
    buf_en = 0;
    
    // Wait a few cycles, then deassert reset
    #15;
    rst = 0;
    #10;

    // --------------------------------------------------------
    // Test Case 1: Write the first line
    // Expected: pixel_prev will output 'x' (unknown) because 
    // the memory array is uninitialized at startup.
    // --------------------------------------------------------
    $display("--- Writing Line 1 ---");
    buf_en = 1;
    for (int i = 0; i < TEST_WIDTH; i++) begin
      pixel = 8'd10 + i; // Feed values: 10, 11, 12... 17
      #10;
    end

    // --------------------------------------------------------
    // Test Case 2: Write the second line
    // Expected: pixel_prev should now output the values stored 
    // during Line 1 (10, 11, 12... 17).
    // --------------------------------------------------------
    $display("--- Writing Line 2 (Should read back Line 1) ---");
    for (int i = 0; i < TEST_WIDTH; i++) begin
      pixel = 8'd20 + i; // Feed values: 20, 21, 22... 27
      #10;
    end

    // --------------------------------------------------------
    // Test Case 3: Test buf_en functionality
    // Expected: The pointer should pause when buf_en is low,
    // and ignore any new pixel data.
    // --------------------------------------------------------
    $display("--- Testing buf_en (Pausing halfway) ---");
    
    // Write first half of Line 3
    for (int i = 0; i < 4; i++) begin
      pixel = 8'd30 + i; 
      #10;
    end
    
    // Disable buffer for 3 clock cycles
    buf_en = 0;
    pixel = 8'd99; // This value should not be written to memory
    $display("    Buffer Disabled. New data should be ignored.");
    #30; 
    
    // Re-enable and finish the line
    buf_en = 1;
    for (int i = 4; i < TEST_WIDTH; i++) begin
      pixel = 8'd30 + i;
      #10;
    end
    
    // Wait a few cycles to observe the final state
    #20;
    $display("Simulation Complete.");
    $finish;
  end

  // Monitor the behavior in the console
  // Using dut.col_ptr allows viewing the internal pointer
  initial begin
    $monitor("Time=%0t | rst=%b | buf_en=%b | in=%0d | out(pixel_prev)=%0d | col_ptr=%0d", 
             $time, rst, buf_en, pixel, pixel_prev, dut.col_ptr);
  end

endmodule