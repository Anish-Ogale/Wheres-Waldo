`timescale 1ns / 1ps

module tb_sys8();

    // Inputs
    logic clk;
    logic rst;
    logic signed [7:0] weight [0:7][0:7];
    logic signed [7:0] pixel_raw [0:7]; // The flat, unskewed vector from memory
    logic signed [7:0] pixel [0:7];     // The delayed, skewed vector feeding the array

    // Outputs
    logic signed [31:0] sum [0:7];

    // Instantiate the Unit Under Test (UUT)
    sys8 uut (
        .clk(clk),
        .rst(rst),
        .weight(weight),
        .pixel(pixel), // Connect the skewed pixels to the array
        .sum(sum)
    );

    // ---------------------------------------------------------
    // SKEWING LOGIC: Shift register array to delay row i by i cycles
    // ---------------------------------------------------------
    logic signed [7:0] skew_pipe [0:7][0:7]; 

    always_ff @(posedge clk) begin
        if (rst) begin
            for (int i = 0; i < 8; i++) begin
                pixel[i] <= 8'd0;
                for (int j = 0; j < 8; j++) begin
                    skew_pipe[i][j] <= 8'd0;
                end
            end
        end else begin
            for (int i = 0; i < 8; i++) begin
                // Shift data into the pipeline
                skew_pipe[i][0] <= pixel_raw[i];
                for (int j = 1; j < 8; j++) begin
                    skew_pipe[i][j] <= skew_pipe[i][j-1];
                end
                
                // Tap the pipeline at the correct depth for each row
                if (i == 0) begin
                    pixel[0] <= pixel_raw[0]; // Row 0 has 0 delay
                end else begin
                    pixel[i] <= skew_pipe[i][i-1]; // Row i has i delay
                end
            end
        end
    end

    // Clock generation (100MHz)
    always #5 clk = ~clk;

    initial begin
        // Initialize Inputs
        clk = 0;
        rst = 1;
        for (int i = 0; i < 8; i++) begin
            pixel_raw[i] = 8'd0;
            for (int j = 0; j < 8; j++) weight[i][j] = 8'd0;
        end

        // Wait for global reset
        #100;
        @(posedge clk);
        rst = 0;

        // Load test weights (Matrix of 1s for easy math verification)
        for (int i = 0; i < 8; i++) begin
            for (int j = 0; j < 8; j++) begin
                weight[i][j] = 8'd1; 
            end
        end

        // Feed first unskewed pixel vector
        @(posedge clk);
        for (int i = 0; i < 8; i++) pixel_raw[i] = 8'd2; 

        // Feed second unskewed pixel vector
        @(posedge clk);
        for (int i = 0; i < 8; i++) pixel_raw[i] = 8'd3; 

        // Stop feeding inputs
        @(posedge clk);
        for (int i = 0; i < 8; i++) pixel_raw[i] = 8'd0; 

        // Wait for the pipeline to completely flush
        repeat(30) @(posedge clk);

        $finish;
    end

    // Monitor output
    initial begin
        $monitor("Time=%0t | sum[0]=%0d, sum[7]=%0d", $time, sum[0], sum[7]);
    end

endmodule