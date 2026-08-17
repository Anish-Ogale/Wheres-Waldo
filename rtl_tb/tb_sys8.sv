module tb_sys_para();

    parameter SIZE = 8;
    
    reg clk;
    reg rst;
    reg load_en;
    reg signed [7:0] weight [0:SIZE-1];
    reg signed [7:0] pixel [0:SIZE-1];
    wire signed [31:0] sum [0:SIZE-1];

    // Instantiate the Array
    sys_para #(.size(SIZE)) uut (
        .clk(clk),
        .rst(rst),
        .load_en(load_en),
        .weight(weight),
        .pixel(pixel),
        .sum(sum)
    );

    // Clock generation (10ns period)
    always #5 clk = ~clk;

    // Track how many cycles we've been computing for the manual skew
    integer compute_cycles = 0;

    // Staggered Pixel Generator (Mimics the Skew module)
    always @(posedge clk) begin
        if (rst) begin
            for(int i=0; i<SIZE; i++) pixel[i] <= 0;
            compute_cycles <= 0;
        end else if (!load_en) begin
            compute_cycles <= compute_cycles + 1;
            // Feed a '1' into Row i only AFTER 'i' clock cycles have passed
            for(int i=0; i<SIZE; i++) begin
                pixel[i] <= (compute_cycles >= i) ? 8'd1 : 8'd0;
            end
        end
    end

    // Main Test Sequence
    initial begin
        // 1. Initialize
        clk = 0;
        rst = 1;
        load_en = 0;
        for(int i=0; i<SIZE; i++) weight[i] = 0;
        
        #20; // Hold reset
        rst = 0;
        
        // 2. Load Weights Phase (Hold for exactly 8 clocks)
        load_en = 1;
        for(int i=0; i<SIZE; i++) begin
            weight[i] = i + 1; // Col 0 gets 1s, Col 1 gets 2s... Col 7 gets 8s
        end
        
        #80; // 8 clock cycles (8 * 10ns)
        
        // 3. Lock Weights & Start Computing Phase
        load_en = 0;
        
        // Let it run for enough cycles for the math to reach the bottom
        #200; 
        
        // Print the final outputs at the bottom of the array
        $display("========================================");
        $display("FINAL ACCUMULATED SUMS:");
        for(int i=0; i<SIZE; i++) begin
            $display("Column %0d Sum: %0d (Expected: %0d)", i, sum[i], 8*(i+1));
        end
        $display("========================================");
        
        $finish;
    end

endmodule