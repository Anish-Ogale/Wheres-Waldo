`timescale 1ns / 1ps

module accumulator #(
    parameter width = 32,
    parameter depth = 512
)(
    input clk,
    input rst,

    input valid_in,
    input [width-1:0] data_in,
    input [8:0] addr_in,
    input first,
    input last,

    output reg valid_out,
    output reg [width-1:0] data_out,
    output reg [8:0] addr_out
);
reg [width-1:0] mem [0:depth-1];
reg [width-1:0] rd_data;
reg [width-1:0] data_in_r;
reg first_r, valid_in_r, last_r;
reg [8:0] addr_in_r;

always @(posedge clk) begin
    rd_data    <= mem[addr_in];      // synchronous read -> BRAM-inferable
    data_in_r  <= data_in;
    first_r    <= first;
    valid_in_r <= valid_in;
    last_r     <= last;
    addr_in_r  <= addr_in;
end

wire [width-1:0] next = first_r ? data_in_r : rd_data + data_in_r;

always @(posedge clk) begin
    if (rst) begin
        valid_out <= 1'b0;
    end else begin
        valid_out <= 1'b0;
        if (valid_in_r) begin
            mem[addr_in_r] <= next;
            if (last_r) begin
                data_out  <= next;
                addr_out  <= addr_in_r;
                valid_out <= 1'b1;
            end
        end
    end
end


endmodule