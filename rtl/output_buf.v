`timescale 1ns / 1ps

module ofm_buffer #(
    parameter DATA_WIDTH = 8,
    parameter ARRAY_SIZE = 8,
    parameter ADDR_WIDTH = 10
)(
    input clk,
    input rst,

    input wr_en,
    input [ADDR_WIDTH-1:0] wr_addr,
    input [(DATA_WIDTH*ARRAY_SIZE)-1:0] wr_data,
    output wire wr_ready,
    input wr_done,
   
    input tile_start,
    input pool_enable,
    input [ADDR_WIDTH-1:0] expected_writes,
    output reg stream_done,

    input rd_en,
    input [ADDR_WIDTH:0] rd_addr,
    output reg signed [(DATA_WIDTH*ARRAY_SIZE/2)-1:0] rd_data,
    output wire rd_valid,
    input rd_done
);

    localparam WORD_WIDTH = DATA_WIDTH * ARRAY_SIZE;
    localparam HALF_WIDTH = WORD_WIDTH / 2;
    localparam DEPTH = (1 << ADDR_WIDTH);

    (* ram_style = "block" *) reg [WORD_WIDTH-1:0] buff_1 [0:DEPTH-1];
    (* ram_style = "block" *) reg [WORD_WIDTH-1:0] buff_2 [0:DEPTH-1];

    reg wr_select;
    reg rd_select;

    reg buff_1_full;
    reg buff_2_full;

    reg [WORD_WIDTH-1:0] raw_rd_data;
    reg rd_half_sel;
    reg [ADDR_WIDTH-1:0] pooled_wr_addr;
    wire [ADDR_WIDTH-1:0] selected_wr_addr = pool_enable ? pooled_wr_addr : wr_addr;

    assign wr_ready = (wr_select == 1'b0) ? ~buff_1_full : ~buff_2_full;
    assign rd_valid = (rd_select == 1'b0) ? buff_1_full : buff_2_full;

    always @(posedge clk) begin
        if (rst) begin
            wr_select   <= 1'b0;
            rd_select   <= 1'b0;
            buff_1_full <= 1'b0;
            buff_2_full <= 1'b0;
        end
        else begin
            if (wr_done) begin
                if (wr_select == 1'b0) begin
                    buff_1_full <= 1'b1;
                    wr_select   <= 1'b1;
                end
                else begin
                    buff_2_full <= 1'b1;
                    wr_select   <= 1'b0;
                end
            end

            if (rd_done) begin
                if (rd_select == 1'b0) begin
                    buff_1_full <= 1'b0;
                    rd_select   <= 1'b1;
                end
                else begin
                    buff_2_full <= 1'b0;
                    rd_select   <= 1'b0;
                end
            end
        end
    end

    always @(posedge clk) begin
        if (rst || tile_start) begin
            pooled_wr_addr <= {ADDR_WIDTH{1'b0}};
            stream_done <= 1'b0;
        end else if (wr_en && wr_ready && !stream_done) begin
            if (wr_select == 1'b0)
                buff_1[selected_wr_addr] <= wr_data;
            else
                buff_2[selected_wr_addr] <= wr_data;

            if (selected_wr_addr == expected_writes - 1'b1)
                stream_done <= 1'b1;
            else if (pool_enable)
                pooled_wr_addr <= pooled_wr_addr + 1'b1;
        end
    end

    always @(posedge clk) begin
        if (rd_en && rd_valid) begin
            if (rd_addr[0] == 1'b0) begin
                if (rd_select == 1'b0)
                    raw_rd_data <= buff_1[rd_addr[ADDR_WIDTH:1]];
                else
                    raw_rd_data <= buff_2[rd_addr[ADDR_WIDTH:1]];
            end
            rd_half_sel <= rd_addr[0];
        end
    end

    always @(*) begin
        rd_data = rd_half_sel ? raw_rd_data[WORD_WIDTH-1:HALF_WIDTH] : raw_rd_data[HALF_WIDTH-1:0];
    end

endmodule
