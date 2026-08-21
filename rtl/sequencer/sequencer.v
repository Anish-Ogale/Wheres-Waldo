`timescale 1ns / 1ps

module sequencer #(

localparam IDLE = 2'd0,
localparam ISSUE = 2'd1,
localparam WAIT = 2'd2

)(

        input clk,
        input rst,

        input [1:0] region_sel,
        input we,
        input [3:0] layer_count,
        input [7:0] in_tile,
        input [7:0] out_tile,
        input [1:0] kx,
        input [1:0] ky,
        input [8:0] x,
        input [8:0] y,
        input [7:0] num_in_tiles,
        input [8:0] width_in,
        input kernel_size,
        input [31:0] local_addr,

        input awready,
        output [7:0] awlen,
        output awvalid,
        output [31:0] awaddr,

        input wready,
        output [31:0] wdata,
        output [3:0] wstrb,
        output wlast,
        output wvalid,

        input [1:0] bresp,
        input bvalid,
        output bready,

        input [31:0] rdata,
        input rlast,
        input rvalid,
        output rready,

        output [31:0] araddr,
        output [7:0] arlen,
        output arvalid,
        input arready,

        output [31:0] bram_wdata,
        output bram_we,
        input [31:0] bram_rdata,
        output [31:0] bram_addr,

        input req,
        output reg done

    );


    wire [31:0] gen_ddr_addr;
    wire [7:0] gen_length;
    wire gen_more_beats;

    reg [8:0] beat_offset;
    reg [31:0] local_addr_reg;
    reg axi_req;
    wire axi_ack;

    reg [1:0] state;


    address_gen u_addr_gen (
        .layer_count(layer_count),
        .in_tile(in_tile),
        .out_tile(out_tile),
        .kx(kx),
        .ky(ky),
        .x(x),
        .y(y),
        .num_in_tiles(num_in_tiles),
        .width_in(width_in),
        .region_sel(region_sel),
        .kernel_size(kernel_size),
        .beat_offset(beat_offset),
        .more_beats(gen_more_beats),
        .ddr_addr(gen_ddr_addr),
        .length(gen_length)
    );


    AXI_Master u_axi_master (
        .clk(clk),
        .rst(rst),
        .req(axi_req),
        .we(we),
        .ddr_addr(gen_ddr_addr),
        .local_addr(local_addr_reg),
        .length(gen_length),
        .ack(axi_ack),

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
        .bram_we(bram_we),
        .bram_rdata(bram_rdata),
        .bram_addr(bram_addr)
    );


    always @(posedge clk) begin
        if(rst) begin
            axi_req <= 1'b0;
            done <= 1'd0;
            state <= IDLE;
            beat_offset <= 9'd0;
            local_addr_reg <= 32'd0;
        end else begin
            case(state)
                IDLE: begin
                    axi_req <= 1'b0;
                    done <= 1'd0;
                    if(req) begin
                        local_addr_reg <= local_addr + beat_offset;
                        state <= ISSUE;
                    end
                end

                ISSUE : begin
                    axi_req <= 1'b1;
                    state<= WAIT;
                end

                WAIT: begin
                    axi_req <= 1'b1;
                    if(axi_ack) begin
                        axi_req <= 1'b0;
                        if(gen_more_beats) begin
                            beat_offset <= beat_offset + gen_length;
                            local_addr_reg <= local_addr_reg + gen_length;
                            state <= ISSUE;
                        end else begin
                            beat_offset <= 9'd0;
                            done <= 1'b1;
                            state <= IDLE;
                        end
                    end
                end

            endcase
        end
    end


endmodule
