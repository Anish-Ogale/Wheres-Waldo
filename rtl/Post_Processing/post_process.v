`timescale 1ns / 1ps

module post_process (
    input clk,
    input rst,
    input valid_in,
    input [255:0] data_in,
    input [8:0] addr_in,
    input first,
    input last,
    input relu_enable_r,
    input signed [15:0] scale,
    input [4:0] shift,
    output out_valid,
    output [63:0] data_out
);

    wire acc_valid_out;
    wire [255:0] acc_data_out;
    wire [8:0] acc_addr_out;
    wire [255:0] relu_data_out;
    reg relu_valid_out;
    reg [255:0] acc_data_out_d;
    reg relu_enable_d;
    wire [255:0] post_relu_data;

    reg signed [15:0] scale_pipe [0:2];
    reg [4:0] shift_pipe [0:2];

    initial begin
        scale_pipe[0] = 0; scale_pipe[1] = 0; scale_pipe[2] = 0;
        shift_pipe[0] = 0; shift_pipe[1] = 0; shift_pipe[2] = 0;
        relu_valid_out = 0;
        relu_enable_d = 0;
    end

    always @(posedge clk) begin
        scale_pipe[0] <= scale;
        shift_pipe[0] <= shift;

        scale_pipe[1] <= scale_pipe[0];
        shift_pipe[1] <= shift_pipe[0];

        scale_pipe[2] <= scale_pipe[1];
        shift_pipe[2] <= shift_pipe[1];
    end

    accumulator #(
        .width(256),
        .depth(512)
    ) u_accumulator (
        .clk(clk),
        .rst(rst),
        .valid_in(valid_in),
        .data_in(data_in),
        .addr_in(addr_in),
        .first(first),
        .last(last),
        .valid_out(acc_valid_out),
        .data_out(acc_data_out),
        .addr_out(acc_addr_out)
    );

    Leaky_ReLU u_leaky_relu (
        .clk(clk),
        .deskewed_flat(acc_data_out),
        .leaked_flat(relu_data_out)
    );

    always @(posedge clk) begin
        if (rst) begin
            relu_valid_out <= 1'b0;
            relu_enable_d <= 1'b0;
            acc_data_out_d <= 256'd0;
        end else begin
            relu_valid_out <= acc_valid_out;
            relu_enable_d <= relu_enable_r;
            acc_data_out_d <= acc_data_out;
        end
    end

    assign post_relu_data = relu_enable_d ? relu_data_out : acc_data_out_d;

    quantizer #(
        .NUM_CHANNELS(8)
    ) u_quantizer (
        .clk(clk),
        .rst(rst),
        .in_valid(relu_valid_out),
        .out_valid(out_valid),
        .scale(scale_pipe[2]),
        .shift(shift_pipe[2]),
        .in_data_flat(post_relu_data),
        .out_data_flat(data_out)
    );

endmodule