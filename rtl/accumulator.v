`timescale 1ns / 1ps

module accumulator #(
    parameter width = 32,
    parameter depth = 512
)(
    input clk,
    input rst,

    input validin,
    input [width-1:0] datain,
    input [8:0] addrin,
    input first,
    input last,

    output reg validout,
    output reg [width-1:0] dataout,
    output reg [8:0] addrout
);

    reg [width-1:0] mem [0:depth-1];
    wire [width-1:0] next = first ? datain : mem[addrin] + datain;

    always @(posedge clk) begin
        if(rst) begin
            validout <= 1'b0;
        end else begin
            validout <= 1'b0;
            if(validin) begin
                mem[addrin] <= next;
                if(last) begin
                    dataout  <= next;
                    addrout  <= addrin;
                    validout <= 1'b1;
                end
            end
        end
    end

endmodule