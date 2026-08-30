// Code your testbench here
// or browse Examples
`timescale 1ns / 1ps

module tb_FSM;

    // ---------------------------------------------------------
    // Signal Declarations
    // ---------------------------------------------------------
    // Inputs to DUT
    reg clk;
    reg rst;
    reg start;
    reg [4:0] quantizer;
    reg seq_done;
    reg pool_done;

    // Outputs from DUT
    wire swap;
    wire valid_in;
    wire padding;
    wire done;
    wire req;
    wire we;
    wire [1:0] region_sel;
    wire [3:0] layer_count;
    wire [7:0] in_tile;
    wire [7:0] out_tile;
    wire [1:0] kx;
    wire [1:0] ky;
    wire [8:0] x;
    wire [8:0] y;
    wire [8:0] width_in_r;
    wire [7:0] num_in_tiles_r;
    wire kernel_size_r;
    wire first_pass;
    wire finalize;
    wire pool_start;
    wire pool_select;
    wire relu_enable_r;

    // ---------------------------------------------------------
    // Clock Generation (100 MHz)
    // ---------------------------------------------------------
    initial clk = 0;
    always #5 clk = ~clk; 

    // ---------------------------------------------------------
    // DUT Instantiation
    // ---------------------------------------------------------
    FSM dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .swap(swap),
        .valid_in(valid_in),
        .padding(padding),
        .quantizer(quantizer),
        .done(done),
        .req(req),
        .seq_done(seq_done),
        .we(we),
        .region_sel(region_sel),
        .layer_count(layer_count),
        .in_tile(in_tile),
        .out_tile(out_tile),
        .kx(kx),
        .ky(ky),
        .x(x),
        .y(y),
        .width_in_r(width_in_r),
        .num_in_tiles_r(num_in_tiles_r),
        .kernel_size_r(kernel_size_r),
        .first_pass(first_pass),
        .finalize(finalize),
        .pool_start(pool_start),
        .pool_done(pool_done),
        .pool_select(pool_select),
        .relu_enable_r(relu_enable_r)
    );

    // ---------------------------------------------------------
    // Emulators for External Peripherals (Memory & Pooling)
    // ---------------------------------------------------------
    reg [3:0] seq_delay_counter;
    reg [3:0] pool_delay_counter;

    // Memory Controller Emulator (responds to 'req' with 'seq_done')
    always @(posedge clk) begin
        if (rst) begin
            seq_delay_counter <= 4'd0;
            seq_done <= 1'b0;
        end else begin
            seq_done <= 1'b0; // Default to 0 (pulse)
            
            if (req) begin
                // Simulate a 5-cycle memory access latency
                seq_delay_counter <= 4'd5;
            end else if (seq_delay_counter > 4'd1) begin
                seq_delay_counter <= seq_delay_counter - 1'b1;
            end else if (seq_delay_counter == 4'd1) begin
                seq_done <= 1'b1; // Assert seq_done for 1 cycle
                seq_delay_counter <= 4'd0;
            end
        end
    end

    // Pooling Module Emulator (responds to 'pool_start' with 'pool_done')
    always @(posedge clk) begin
        if (rst) begin
            pool_delay_counter <= 4'd0;
            pool_done <= 1'b0;
        end else begin
            pool_done <= 1'b0; // Default to 0 (pulse)
            
            if (pool_start) begin
                // Simulate a 10-cycle pooling operation latency
                pool_delay_counter <= 4'd10;
            end else if (pool_delay_counter > 4'd1) begin
                pool_delay_counter <= pool_delay_counter - 1'b1;
            end else if (pool_delay_counter == 4'd1) begin
                pool_done <= 1'b1; // Assert pool_done for 1 cycle
                pool_delay_counter <= 4'd0;
            end
        end
    end

    // ---------------------------------------------------------
    // Progress Monitor
    // ---------------------------------------------------------
    reg [3:0] prev_layer;
    
    always @(posedge clk) begin
        if (!rst) begin
            if (layer_count != prev_layer) begin
                $display("[%0t ns] Completed Layer %0d. Transitioning to Layer %0d...", 
                         $time, prev_layer, layer_count);
                prev_layer <= layer_count;
            end
        end
    end

    // ---------------------------------------------------------
    // Main Test Stimulus
    // ---------------------------------------------------------
    initial begin
        // Initialize Inputs
        rst = 1'b1;
        start = 1'b0;
        quantizer = 5'd0;
        prev_layer = 4'd0;

        $display("=================================================");
        $display(" Starting FSM Functional Verification Testbench  ");
        $display("=================================================");

        // Hold reset for 100ns
        #100;
        @(posedge clk);
        rst = 1'b0;
        $display("[%0t ns] Reset Deasserted.", $time);

        // Wait a few cycles, then pulse start
        repeat(5) @(posedge clk);
        start = 1'b1;
        @(posedge clk);
        start = 1'b0;
        
        $display("[%0t ns] START command issued. FSM is processing...", $time);

        // Wait until the FSM asserts the 'done' signal
        wait (done == 1'b1);
        
        $display("=================================================");
        $display("[%0t ns] SUCCESS: FSM Processing Complete!", $time);
        $display("=================================================");
        
        // Wait 100ns before ending simulation
        #100;
        $finish;
    end

    // ---------------------------------------------------------
    // Watchdog Timer (Timeout safeguard against infinite loops)
    // ---------------------------------------------------------
    // Set to 500 million ns (500 ms). Given the massive 
    // number of pixels across 9 layers, this sim will take 
    // approx 20M to 30M cycles.
    // ---------------------------------------------------------
    // Watchdog Timer (Timeout safeguard against infinite loops)
    // ---------------------------------------------------------
    initial begin
        #1_500_000_000;  // <-- Increased to 1.5 billion
        $display("[%0t ns] ERROR: Simulation Timeout Reached! FSM Deadlocked.", $time);
        $finish;
    end

endmodule