`timescale 1ns / 1ps

module tb_Leaky_ReLU();

  // Testbench signals
  reg clk;
  reg signed [31:0] deskewed [0:7];
  wire signed [31:0] leaked [0:7];

  // Instantiate the Device Under Test (DUT)
  Leaky_ReLU dut (
    .clk(clk),
    .deskewed(deskewed),
    .leaked(leaked)
  );

  // Clock generation: 10ns period (100 MHz)
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  // Stimulus process
  initial begin
    // Initialize inputs to zero
    for (int i = 0; i < 8; i++) begin
      deskewed[i] = 32'sd0;
    end

    // Wait for initial stabilization
    #15; 

    // --------------------------------------------------------
    // Test Case 1: Positive numbers and Zero
    // Expected: Values should pass through unchanged
    // --------------------------------------------------------
    $display("--- Test Case 1: Positive Numbers & Zero ---");
    deskewed[0] = 32'sd0;
    deskewed[1] = 32'sd10;
    deskewed[2] = 32'sd100;
    deskewed[3] = 32'sd256;
    deskewed[4] = 32'sd512;
    deskewed[5] = 32'sd1024;
    deskewed[6] = 32'sd2048;
    deskewed[7] = 32'sd4096;
    #10; // Wait for one clock cycle

    // --------------------------------------------------------
    // Test Case 2: Negative numbers
    // Expected: Values multiplied by 26 and divided by 256
    // Example: -256 * 26 / 256 = -26
    // --------------------------------------------------------
    $display("--- Test Case 2: Negative Numbers ---");
    deskewed[0] = -32'sd256;  // Expected output: -26
    deskewed[1] = -32'sd512;  // Expected output: -52
    deskewed[2] = -32'sd1024; // Expected output: -104
    deskewed[3] = -32'sd128;  // Expected output: -13
    deskewed[4] = -32'sd10;   // Expected output: near 0 (truncated)
    deskewed[5] = -32'sd2000;
    deskewed[6] = -32'sd4096;
    deskewed[7] = -32'sd8192;
    #10;

    // --------------------------------------------------------
    // Test Case 3: Mixed positive and negative numbers
    // --------------------------------------------------------
    $display("--- Test Case 3: Mixed Array ---");
    deskewed[0] = 32'sd150;
    deskewed[1] = -32'sd256;
    deskewed[2] = 32'sd999;
    deskewed[3] = -32'sd1024;
    deskewed[4] = 32'sd0;
    deskewed[5] = -32'sd512;
    deskewed[6] = 32'sd42;
    deskewed[7] = -32'sd128;
    #10;

    // Allow time to observe the final registered outputs
    #10;
    $display("Simulation Complete.");
    $finish;
  end

  // Monitor changes to specific array indices to verify functionality in the console
  initial begin
    $monitor("Time=%0t | in[0]=%0d, out[0]=%0d | in[1]=%0d, out[1]=%0d", 
             $time, deskewed[0], leaked[0], deskewed[1], leaked[1]);
  end

endmodule