`timescale 1ns / 1ps

module tb_top ();

    // Clock and Reset
    reg clk;
    reg rst;
    reg start;

    // AXI4 Master Interface
    wire awready;
    wire [7:0] awlen;
    wire awvalid;
    wire [31:0] awaddr;

    wire wready;
    wire [63:0] wdata;
    wire [7:0] wstrb;
    wire wlast;
    wire wvalid;

    wire [1:0] bresp;
    wire bvalid;
    wire bready;

    wire [63:0] rdata;
    wire rlast;
    wire rvalid;
    wire rready;

    wire [31:0] araddr;
    wire [7:0] arlen;
    wire arvalid;
    wire arready;

    // Instantiate Top Module
    top u_top (
        .clk(clk),
        .rst(rst),
        .start(start),
        
        .awready(awready),
        .awlen(awlen),
        .awvalid(awvalid),
        .awaddr(awaddr),
        
        .wready(wready),
        .wdata(wdata),
        .wstrb(wstrb),
        .wlast(wlast),
        .wvalid(wvalid),
        
        .bresp(bresp),
        .bvalid(bvalid),
        .bready(bready),
        
        .rdata(rdata),
        .rlast(rlast),
        .rvalid(rvalid),
        .rready(rready),
        
        .araddr(araddr),
        .arlen(arlen),
        .arvalid(arvalid),
        .arready(arready)
    );

    // Clock Generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100MHz clock
    end

    // ---------------------------------------------------------
    // Simple AXI Slave Memory Model (16MB Word-Addressable DDR)
    // ---------------------------------------------------------
    reg [63:0] mem [0:2097151]; // 2M double-words = 16MB

    // Read Channels
    reg arready_reg;
    reg rvalid_reg;
    reg [63:0] rdata_reg;
    reg rlast_reg;
    
    assign arready = arready_reg;
    assign rvalid = rvalid_reg;
    assign rdata = rdata_reg;
    assign rlast = rlast_reg;
    
    reg [31:0] read_addr;
    reg [7:0] read_len;
    reg [7:0] read_count;
    
    typedef enum logic [1:0] {R_IDLE, R_DATA} r_state_t;
    r_state_t r_state;

    always @(posedge clk) begin
        if (rst) begin
            arready_reg <= 1;
            rvalid_reg <= 0;
            rlast_reg <= 0;
            rdata_reg <= 0;
            r_state <= R_IDLE;
        end else begin
            case (r_state)
                R_IDLE: begin
                    if (arvalid && arready) begin
                        read_addr <= araddr;
                        read_len <= arlen;
                        read_count <= 0;
                        arready_reg <= 0;
                        
                        rvalid_reg <= 1;
                        rdata_reg <= mem[araddr >> 3]; // 8 bytes per word
                        rlast_reg <= (arlen == 0);
                        r_state <= R_DATA;
                    end else begin
                        arready_reg <= 1;
                    end
                end
                R_DATA: begin
                    if (rvalid && rready) begin
                        if (read_count == read_len) begin
                            rvalid_reg <= 0;
                            rlast_reg <= 0;
                            arready_reg <= 1;
                            r_state <= R_IDLE;
                        end else begin
                            read_count <= read_count + 1;
                            read_addr <= read_addr + 8;
                            rdata_reg <= mem[(read_addr + 8) >> 3];
                            rlast_reg <= (read_count + 1 == read_len);
                        end
                    end
                end
            endcase
        end
    end

    // Write Channels
    reg awready_reg;
    reg wready_reg;
    reg bvalid_reg;
    reg [1:0] bresp_reg;
    
    assign awready = awready_reg;
    assign wready = wready_reg;
    assign bvalid = bvalid_reg;
    assign bresp = bresp_reg;
    
    reg [31:0] write_addr;
    
    typedef enum logic [1:0] {W_IDLE, W_DATA, W_RESP} w_state_t;
    w_state_t w_state;

    always @(posedge clk) begin
        if (rst) begin
            awready_reg <= 1;
            wready_reg <= 0;
            bvalid_reg <= 0;
            bresp_reg <= 0;
            w_state <= W_IDLE;
        end else begin
            case (w_state)
                W_IDLE: begin
                    if (awvalid && awready) begin
                        write_addr <= awaddr;
                        awready_reg <= 0;
                        wready_reg <= 1;
                        w_state <= W_DATA;
                    end else begin
                        awready_reg <= 1;
                    end
                end
                W_DATA: begin
                    if (wvalid && wready) begin
                        if (wstrb[0]) mem[write_addr >> 3][7:0]   <= wdata[7:0];
                        if (wstrb[1]) mem[write_addr >> 3][15:8]  <= wdata[15:8];
                        if (wstrb[2]) mem[write_addr >> 3][23:16] <= wdata[23:16];
                        if (wstrb[3]) mem[write_addr >> 3][31:24] <= wdata[31:24];
                        if (wstrb[4]) mem[write_addr >> 3][39:32] <= wdata[39:32];
                        if (wstrb[5]) mem[write_addr >> 3][47:40] <= wdata[47:40];
                        if (wstrb[6]) mem[write_addr >> 3][55:48] <= wdata[55:48];
                        if (wstrb[7]) mem[write_addr >> 3][63:56] <= wdata[63:56];
                        
                        if (wlast) begin
                            wready_reg <= 0;
                            bvalid_reg <= 1;
                            bresp_reg <= 0; // OKAY
                            w_state <= W_RESP;
                        end else begin
                            write_addr <= write_addr + 8;
                        end
                    end
                end
                W_RESP: begin
                    if (bvalid && bready) begin
                        bvalid_reg <= 0;
                        awready_reg <= 1;
                        w_state <= W_IDLE;
                    end
                end
            endcase
        end
    end

    // ---------------------------------------------------------
    // Test Sequence
    // ---------------------------------------------------------
    integer i;
    integer modified_count;
    initial begin
        $display("==================================================");
        $display("[%0t] Initializing Memory Model with deterministic values...", $time);
        
        // Fill memory with a deterministic pattern (e.g. 0x0706050403020100 for word 0)
        // Helps to distinguish between default uninitialized states
        for (i = 0; i < 2097152; i = i + 1) begin
            mem[i][63:56] = ($unsigned(i)*8+7)%256;
            mem[i][55:48] = ($unsigned(i)*8+6)%256;
            mem[i][47:40] = ($unsigned(i)*8+5)%256;
            mem[i][39:32] = ($unsigned(i)*8+4)%256;
            mem[i][31:24] = ($unsigned(i)*8+3)%256;
            mem[i][23:16] = ($unsigned(i)*8+2)%256;
            mem[i][15:8]  = ($unsigned(i)*8+1)%256;
            mem[i][7:0]   = ($unsigned(i)*8)%256;
        end
        
        $display("[%0t] Applying Reset...", $time);
        clk = 0;
        rst = 1;
        start = 0;
        
        // Hold reset
        #100;
        rst = 0;
        
        // Wait a few cycles
        #50;
        
        $display("[%0t] Triggering FSM Start...", $time);
        start = 1;
        #10;
        start = 0;
        
        // Let simulation run for Layer 0
        // Wait for FSM layer count to increment to 1, indicating Layer 0 finished
        // Or timeout after a reasonable period
        fork
            begin
                wait (u_top.u_FSM.tile_x_base == 48); // Wait until Tile 3 starts
                $display("[%0t] Tile 3 Reached! Exiting early for fast testing.", $time);
            end
            begin
                #50000000; // 50ms Timeout for simulation (adjust as necessary for full layer processing)
                $display("[%0t] Timeout reached. This might be normal if the layer takes a long time.", $time);
            end
        join_any
        
        $display("[%0t] Simulation finished. Inspecting modified memory locations for Output Feature Maps (OFMs):", $time);
        
        // Inspect a slice of memory to check if anything was overwritten
        // We only print the first 10 modifications to avoid terminal spam
        modified_count = 0;
        for (i = 0; i < 2097152; i = i + 1) begin
            if (
                mem[i][63:56] !== (($unsigned(i)*8+7)%256) ||
                mem[i][55:48] !== (($unsigned(i)*8+6)%256) ||
                mem[i][47:40] !== (($unsigned(i)*8+5)%256) ||
                mem[i][39:32] !== (($unsigned(i)*8+4)%256) ||
                mem[i][31:24] !== (($unsigned(i)*8+3)%256) ||
                mem[i][23:16] !== (($unsigned(i)*8+2)%256) ||
                mem[i][15:8]  !== (($unsigned(i)*8+1)%256) ||
                mem[i][7:0]   !== (($unsigned(i)*8)%256)
            ) begin
                modified_count = modified_count + 1;
                if (modified_count <= 10) begin
                    $display("Mem[%0h] (Addr %0h) = %h", i, i*8, mem[i]);
                end
            end
        end
        $display("[%0t] Total modified memory words (OFM writes): %0d", $time, modified_count);
        
        $display("==================================================");
        $finish;
    end
    
    // ---------------------------------------------------------
    // Monitoring State Changes
    // ---------------------------------------------------------
    // Reduced printing to avoid console spam
    reg [3:0] prev_state;
    initial prev_state = 4'hF; // Invalid initially
    
    always @(posedge clk) begin
        if (!rst && (u_top.u_FSM.current_state != prev_state)) begin
            prev_state <= u_top.u_FSM.current_state;
            
            // Only print major milestones to avoid terminal spam
            if (u_top.u_FSM.current_state == 1)
                $display("[%0t] FSM: LOAD_LAYER_PARAMS (Layer %0d)", $time, u_top.u_FSM.layer_count);
            else if (u_top.u_FSM.current_state == 7 && u_top.u_FSM.out_tile == 0) // Only print the start of writeback for each spatial tile
                $display("[%0t] FSM: WRITEBACK (Tile X:%0d, Y:%0d)", $time, u_top.u_FSM.tile_x_base, u_top.u_FSM.tile_y_base);
        end
    end

    // X Monitor
    always @(posedge clk) begin
        if (!rst) begin
            if (u_top.pixel_in === 64'hx) $display("[%0t] ERROR: pixel_in is X!", $time);
            if (u_top.weight_in === 64'hx && u_top.load_en) $display("[%0t] ERROR: weight_in is X when load_en=1!", $time);
            if (u_top.sum_out === 256'hx && u_top.calc_valid_out) $display("[%0t] ERROR: sum_out is X when calc_valid_out=1!", $time);
            if (u_top.post_data_out === 64'hx && u_top.post_out_valid) $display("[%0t] ERROR: post_data_out is X when post_out_valid=1!", $time);
            if (u_top.pooled_flat === 64'hx && u_top.pool_valid_out) $display("[%0t] ERROR: pooled_flat is X when pool_valid_out=1!", $time);
            if (u_top.wdata === 64'hx && u_top.wvalid) $display("[%0t] ERROR: wdata is X when wvalid=1!", $time);
        end
    end

endmodule
