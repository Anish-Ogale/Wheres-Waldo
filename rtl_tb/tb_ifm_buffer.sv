`timescale 1ns / 1ps

module tb_ifm_buffer;

    parameter int DATA_WIDTH = 8;
    parameter int ARRAY_SIZE = 8;
    parameter int ADDR_WIDTH = 10;

    logic clk;
    logic rst_n;
    logic wr_en;
    logic [ADDR_WIDTH-1:0] wr_addr;
    logic [(DATA_WIDTH*ARRAY_SIZE)-1:0] wr_data;
    logic wr_ready;
    logic wr_done;
    logic rd_en;
    logic [ADDR_WIDTH-1:0] rd_addr;
    logic signed [DATA_WIDTH-1:0] rd_data [0:ARRAY_SIZE-1];
    logic rd_valid;
    logic rd_done;

    // Instantiate UUT
    ifm_buffer #(
        .DATA_WIDTH(DATA_WIDTH),
        .ARRAY_SIZE(ARRAY_SIZE),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) uut (
        .clk(clk),
        .rst_n(rst_n),
        .wr_en(wr_en),
        .wr_addr(wr_addr),
        .wr_data(wr_data),
        .wr_ready(wr_ready),
        .wr_done(wr_done),
        .rd_en(rd_en),
        .rd_addr(rd_addr),
        .rd_data(rd_data),
        .rd_valid(rd_valid),
        .rd_done(rd_done)
    );

    // 100 MHz Clock Generation
    always #5 clk = ~clk;

    initial begin
        clk     = 0;
        rst_n   = 0;
        wr_en   = 0;
        wr_addr = 0;
        wr_data = 0;
        wr_done = 0;
        rd_en   = 0;
        rd_addr = 0;
        rd_done = 0;

        #20 rst_n = 1;
        #10;

        // --- FRAME 1: WRITE TO BUFF_1 ---
        $display("\n--- Step 1: Writing Frame 1 to Buffer 1 ---");
        if (wr_ready) begin
            wr_en   = 1;
            wr_addr = 10'd0;
            wr_data = 64'h1111111111111111;
            #10;
            wr_addr = 10'd1;
            wr_data = 64'h2222222222222222;
            #10;
            wr_en   = 0;
        end

        // Trigger Ping-Pong Swap (Frame 1 Write Done & Initial Read Done)
        wr_done = 1;
        rd_done = 1;
        #10;
        wr_done = 0;
        rd_done = 0;
        #10;

        // --- FRAME 2: READ BUFF_1 WHILE WRITING BUFF_2 ---
        $display("\n--- Step 2: Parallel Read Buff_1 & Write Buff_2 ---");
        
        // Start Reading Buff_1
        rd_en   = 1;
        rd_addr = 10'd0;
        
        // Start Writing Buff_2
        wr_en   = 1;
        wr_addr = 10'd0;
        wr_data = 64'hAABBCCDDEEFF0011;
        #10;

        rd_addr = 10'd1;
        wr_addr = 10'd1;
        wr_data = 64'h9988776655443322;
        #10;

        rd_en = 0;
        wr_en = 0;
        #20;

        $display("\n>> IFM Buffer Ping-Pong Simulation Complete <<");
        $finish;
    end

    // Monitor Output Data
    always @(posedge clk) begin
        if (rd_en && rd_valid) begin
            #1;
            $display("[IFM READ @ t=%0t] Addr=%0d | rd_data[0]=0x%0h, rd_data[7]=0x%0h", 
                     $time, rd_addr, rd_data[0], rd_data[7]);
        end
    end

endmodule