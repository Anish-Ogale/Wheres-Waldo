`timescale 1ns / 1ps

module ifm_buffer #(
    parameter int DATA_WIDTH = 8,
    parameter int ARRAY_SIZE = 8,
    parameter int ADDR_WIDTH = 10
)(
    input logic clk,
    input logic rst_n,

    input logic wr_en,
    input logic [ADDR_WIDTH-1:0] wr_addr,
    input logic [(DATA_WIDTH*ARRAY_SIZE)-1:0] wr_data,
    output logic wr_ready,
    input logic wr_done,

    input logic rd_en,
    input logic [ADDR_WIDTH-1:0] rd_addr,
    output logic signed [DATA_WIDTH-1:0] rd_data [0:ARRAY_SIZE-1],
    output logic rd_valid,
    input logic rd_done
);

    (* ram_style = "block" *) logic [(DATA_WIDTH*ARRAY_SIZE)-1:0] buff_1 [0:(1<<ADDR_WIDTH)-1];
    (* ram_style = "block" *) logic [(DATA_WIDTH*ARRAY_SIZE)-1:0] buff_2 [0:(1<<ADDR_WIDTH)-1];

    logic buff_select;
    logic buff_1_full;
    logic buff_2_full;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            buff_select <= 1'b0;
            buff_1_full <= 1'b0;
            buff_2_full <= 1'b0;
        end else begin
            if (wr_done) begin
                if (buff_select == 1'b0) buff_1_full <= 1'b1;
                else buff_2_full <= 1'b1;
            end
            if (rd_done) begin
                if (buff_select == 1'b0) buff_2_full <= 1'b0;
                else buff_1_full <= 1'b0;
            end
            if (wr_done && rd_done) begin
                buff_select <= ~buff_select;
            end
        end
    end

    assign wr_ready = (buff_select == 1'b0) ? ~buff_1_full : ~buff_2_full;
    assign rd_valid = (buff_select == 1'b0) ? buff_2_full : buff_1_full;

    always_ff @(posedge clk) begin
        if (wr_en && wr_ready) begin
            if (buff_select == 1'b0) begin
                buff_1[wr_addr] <= wr_data;
            end else begin
                buff_2[wr_addr] <= wr_data;
            end
        end
    end

    logic [(DATA_WIDTH*ARRAY_SIZE)-1:0] raw_rd_data;

    always_ff @(posedge clk) begin
        if (rd_en && rd_valid) begin
            if (buff_select == 1'b0) begin
                raw_rd_data <= buff_2[rd_addr];
            end else begin
                raw_rd_data <= buff_1[rd_addr];
            end
        end
    end

    always_comb begin
        for (int i = 0; i < ARRAY_SIZE; i++) begin
            rd_data[i] = raw_rd_data[(i*DATA_WIDTH) +: DATA_WIDTH];
        end
    end
endmodule
