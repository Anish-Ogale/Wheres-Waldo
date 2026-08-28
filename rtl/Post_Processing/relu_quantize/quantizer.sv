`timescale 1ns / 1ps

module quantizer #(
    parameter NUM_CHANNELS = 8
)(
    input clk,
    input rst,
    input in_valid,
    output reg out_valid,
    input signed [15:0] scale,
    input [4:0] shift,
    input [(NUM_CHANNELS*32)-1:0] in_data_flat,
    output reg [(NUM_CHANNELS*8)-1:0] out_data_flat
);

    reg signed [31:0] in_data [0:NUM_CHANNELS-1];
reg signed [47:0] s1_prod [0:NUM_CHANNELS-1];
    reg signed [31:0] s1_shifted [0:NUM_CHANNELS-1];
    reg s1_valid;

    integer i;

    always @(*) begin
        for (i = 0; i < NUM_CHANNELS; i = i + 1) begin
            in_data[i] = in_data_flat[i*32 +: 32];
            s1_prod[i] = in_data[i] * scale;
        end
    end

   always @(posedge clk) begin
    if (rst) begin
        s1_valid <= 1'b0;
        for (i = 0; i < NUM_CHANNELS; i = i + 1)
            s1_shifted[i] <= 32'sd0;
    end else begin
        s1_valid <= in_valid;
        for (i = 0; i < NUM_CHANNELS; i = i + 1)
            s1_shifted[i] <= s1_prod[i] >>> shift;
    end
end

    always @(posedge clk) begin
        if (rst) begin
            out_valid <= 1'b0;
            out_data_flat <= 0;
        end else begin
            out_valid <= s1_valid;
            for (i = 0; i < NUM_CHANNELS; i = i + 1) begin
                if (s1_shifted[i] > 32'sd127) begin
                    out_data_flat[i*8 +: 8] <= 8'sd127;
                end else if (s1_shifted[i] < -32'sd128) begin
                    out_data_flat[i*8 +: 8] <= -8'sd128;
                end else begin
                    out_data_flat[i*8 +: 8] <= s1_shifted[i][7:0];
                end
            end
        end
    end

endmodule