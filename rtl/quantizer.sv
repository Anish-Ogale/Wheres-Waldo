`timescale 1ns / 1ps

module quantizer #(
    parameter int NUM_CHANNELS = 8
)(
    input  logic        clk,
    input  logic        rst_n,           
    input  logic        in_valid,        
    output logic        out_valid,       
    input  logic signed [15:0] scale,    
    input  logic [4:0]         shift,    
    input  logic signed [31:0] in_data  [0:NUM_CHANNELS-1], 
    output logic signed [7:0]  out_data [0:NUM_CHANNELS-1]  
);

    logic signed [47:0] s1_prod    [0:NUM_CHANNELS-1];
    logic signed [31:0] s1_shifted [0:NUM_CHANNELS-1];
    logic               s1_valid;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s1_valid <= 1'b0;
            for (int i = 0; i < NUM_CHANNELS; i++) begin
                s1_prod[i]    <= '0;
                s1_shifted[i] <= '0;
            end
        end else begin
            s1_valid <= in_valid;
            for (int i = 0; i < NUM_CHANNELS; i++) begin
                s1_prod[i] <= in_data[i] * scale;                                  
                s1_shifted[i] <= 32'(s1_prod[i] >>> shift);
            end
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_valid <= 1'b0;
            for (int i = 0; i < NUM_CHANNELS; i++) begin
                out_data[i] <= 8'sd0;
            end
        end else begin
            out_valid <= s1_valid;
            for (int i = 0; i < NUM_CHANNELS; i++) begin
                if (s1_shifted[i] > 32'sd127) begin
                    out_data[i] <= 8'sd127;   
                end else if (s1_shifted[i] < -32'sd128) begin
                    out_data[i] <= -8'sd128;  
                end else begin
                    out_data[i] <= s1_shifted[i][7:0]; 
                end
            end
        end
    end

endmodule
