`timescale 1ns / 1ps

module top (
    input wire clk,
    input wire rst,
    input wire start,

    input wire awready,
    output wire [7:0] awlen,
    output wire awvalid,
    output wire [31:0] awaddr,

    input wire wready,
    output wire [31:0] wdata,
    output wire [3:0] wstrb,
    output wire wlast,
    output wire wvalid,

    input wire [1:0] bresp,
    input wire bvalid,
    output wire bready,

    input wire [31:0] rdata,
    input wire rlast,
    input wire rvalid,
    output wire rready,

    output wire [31:0] araddr,
    output wire [7:0] arlen,
    output wire arvalid,
    input wire arready
);

    
    wire [1:0] region_sel;
    wire we;
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
    wire req;
    wire seq_done;


    wire wb_rd_en;
    wire [17:0] fmap_read_addr;
    wire ifm_rd_done;


    wire weight_ena;
    wire [9:0] weight_addr;

    
    wire load_en;
    wire padding;
    wire valid_in_fsm;
    wire [17:0] out_pixel_addr_fsm;
    wire first_pass_fsm;
    wire finalize_fsm;

    
    reg valid_in_d;
    reg [17:0] out_pixel_addr_d;
    reg first_pass_d;
    reg finalize_d;

    
    wire relu_enable_r;
    wire signed [15:0] layer_scale;
    wire [4:0] layer_shift;


    wire pool_start;
    wire pool_tile_start;
    wire [4:0] active_tile_width;
    wire [4:0] active_tile_height;
    wire [9:0] ofm_expected_writes;
    wire pool_done; 
    wire pool_select;
    wire pool_enable_r;


    wire ifm_swap, ofm_wr_swap, ofm_rd_swap;
    wire FSM_done;

    
    wire [31:0] bram_wdata;
    wire weight_we;
    wire ifm_we;
    wire [31:0] bram_rdata;
    wire [31:0] bram_addr;

    
    wire signed [63:0] pixel_in;
    wire signed [63:0] weight_in;


    wire signed [255:0] sum_out;
    wire calc_valid_out;
    wire [8:0] calc_addr_out;
    wire calc_first_out;
    wire calc_last_out;

    
    wire post_out_valid;
    wire [63:0] post_data_out;
    wire [8:0] post_addr_out;

    
    wire signed [63:0] pooled_flat;
    wire pool_valid_out;

    
    always @(posedge clk) begin
        if (rst) begin
            valid_in_d         <= 1'b0;
            out_pixel_addr_d   <= 18'd0;
            first_pass_d       <= 1'b0;
            finalize_d         <= 1'b0;
        end else begin
            valid_in_d         <= valid_in_fsm;
            out_pixel_addr_d   <= out_pixel_addr_fsm;
            first_pass_d       <= first_pass_fsm;
            finalize_d         <= finalize_fsm;
        end
    end

    FSM u_FSM (
        .clk(clk),
        .rst(rst),
        .start(start),
        .ifm_swap(ifm_swap),
        .ifm_rd_done(ifm_rd_done),
        .ofm_wr_swap(ofm_wr_swap),
        .ofm_rd_swap(ofm_rd_swap),
        .valid_in(valid_in_fsm),
        .padding(padding),
        .done(FSM_done),
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
        .first_pass(first_pass_fsm),
        .finalize(finalize_fsm),
        .pool_start(pool_start),
        .pool_tile_start(pool_tile_start),
        .active_tile_width(active_tile_width),
        .active_tile_height(active_tile_height),
        .ofm_expected_writes(ofm_expected_writes),
        .pool_done(pool_done),
        .pool_select(pool_select),
        .pool_enable_r(pool_enable_r),
        .relu_enable_r(relu_enable_r),
        .fmap_read_addr(fmap_read_addr),
        .out_pixel_addr(out_pixel_addr_fsm),
        .weight_addr(weight_addr),
        .wb_rd_en(wb_rd_en),
        .weight_ena(weight_ena),
        .load_en(load_en),
        .layer_scale(layer_scale),
        .layer_shift(layer_shift)
    );

    sequencer u_sequencer (
        .clk(clk),
        .rst(rst),
        .region_sel(region_sel),
        .we(we),
        .layer_count(layer_count),
        .in_tile(in_tile),
        .out_tile(out_tile),
        .kx(kx),
        .ky(ky),
        .x(x),
        .y(y),
        .num_in_tiles(num_in_tiles_r),
        .width_in(width_in_r),
        .kernel_size(kernel_size_r),
        
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
        .arready(arready),

        .bram_wdata(bram_wdata),
        .weight_we(weight_we),
        .ifm_we(ifm_we),
        .bram_rdata(bram_rdata),
        .bram_addr(bram_addr),
        .req(req),
        .done(seq_done)
    );

    ifm_buffer #(
        .DATA_WIDTH(8),
        .ARRAY_SIZE(8),
        .ADDR_WIDTH(10)
    ) u_ifm_buffer (
        .clk(clk),
        .rst(rst),
        .wr_en(ifm_we),
        .wr_addr(bram_addr[10:0]), 
        .wr_data(bram_wdata),
        .wr_ready(),
        .wr_done(ifm_swap), 
        .rd_en(valid_in_fsm),
        .rd_addr(fmap_read_addr[9:0]),
        .rd_data(pixel_in),
        .rd_valid(), 
        .rd_done(ifm_rd_done)
    );

    weight_buffer #(
        .DATA_WIDTH(8),
        .ARRAY_SIZE(8),
        .ADDR_WIDTH(10)
    ) u_weight_buffer (
        .clk(clk),
        .rst(rst),
        .we_A(weight_we),
        .addr_A(bram_addr[10:0]),
        .din_A(bram_wdata),
        .ena_B(weight_ena),
        .addr_B(weight_addr[9:0]),
        .dout_B(weight_in)
    );

    calculation_block #(
        .size(8)
    ) u_calculation_block (
        .clk(clk),
        .rst(rst),
        .pixel_in(pixel_in),
        .weight_in(weight_in),
        .load_en(load_en), 
        .padding(padding), 
        .sum_out(sum_out),
        .valid_in(valid_in_d),
        .addr_in(out_pixel_addr_d[8:0]),
        .first_in(first_pass_d),
        .last_in(finalize_d),
        .valid_out(calc_valid_out),
        .addr_out(calc_addr_out),
        .first_out(calc_first_out),
        .last_out(calc_last_out)
    );

    post_process u_post_process (
        .clk(clk),
        .rst(rst),
        .valid_in(calc_valid_out),
        .data_in(sum_out),
        .addr_in(calc_addr_out),
        .first(calc_first_out),
        .last(calc_last_out),
        .relu_enable_r(relu_enable_r),
        .scale(layer_scale),
        .shift(layer_shift),
        .out_valid(post_out_valid),
        .data_out(post_data_out),
        .addr_out(post_addr_out)
    );

    pool_wrapper #(
        .WIDTH(16),
        .NUM_CHANNELS(8)
    ) u_pool_wrapper (
        .clk(clk),
        .rst(rst),
        .tile_start(pool_tile_start),
        .tile_width(active_tile_width),
        .pixel_flat(post_data_out),
        .buf_en(post_out_valid),
        .valid_in(post_out_valid),
        .pool_select(pool_select),
        .pooled_flat(pooled_flat),
        .valid_out(pool_valid_out)
    );

    wire ofm_wr_en = pool_enable_r ? pool_valid_out : post_out_valid;
    wire [63:0] ofm_wr_data = pool_enable_r ? pooled_flat : post_data_out;

    ofm_buffer #(
        .DATA_WIDTH(8),
        .ARRAY_SIZE(8),
        .ADDR_WIDTH(10)
    ) u_ofm_buffer (
        .clk(clk),
        .rst(rst),
        .wr_en(ofm_wr_en),
        .wr_addr({1'b0, post_addr_out}), 
        .wr_data(ofm_wr_data),
        .wr_ready(),
        .wr_done(ofm_wr_swap),
        .tile_start(pool_tile_start),
        .pool_enable(pool_enable_r),
        .expected_writes(ofm_expected_writes),
        .stream_done(pool_done),
        .rd_en(wb_rd_en),
        .rd_addr(bram_addr[10:0]),
        .rd_data(bram_rdata),
        .rd_valid(),
        .rd_done(ofm_rd_swap)
    );

endmodule
