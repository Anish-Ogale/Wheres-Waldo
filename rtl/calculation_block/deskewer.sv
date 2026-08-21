`timescale 1ns / 1ps
module deskewer #(
    parameter size = 8
)(
    input clk,
    input signed [(32*size)-1:0] pixel_in,
    output signed [(32*size)-1:0] pixel_out
);

    wire signed [31:0] p_in [0:size-1];
    wire signed [31:0] p_out [0:size-1];

    genvar g;
    generate
        for(g=0; g<size; g=g+1) begin : pack_unpack
            assign p_in[g] = pixel_in[(g*32) +: 32];
            assign pixel_out[(g*32) +: 32] = p_out[g];
        end
    endgenerate

    reg signed [31:0] r6;
    reg signed [31:0] r5 [0:1];
    reg signed [31:0] r4 [0:2];
    reg signed [31:0] r3 [0:3];
    reg signed [31:0] r2 [0:4];
    reg signed [31:0] r1 [0:5];
    reg signed [31:0] r0 [0:6];

    integer i;

    always @(posedge clk) begin
        r6 <= p_in[6];

        for(i=0;i<2;i=i+1) begin
            if(i==0) begin
                r5[i] <= p_in[5];
            end else begin 
                r5[i] <= r5[i-1];
            end 
        end 

        for(i=0;i<3;i=i+1) begin
            if(i==0) begin
                r4[i] <= p_in[4];
            end else begin 
                r4[i] <= r4[i-1];
            end 
        end 

        for(i=0;i<4;i=i+1) begin
            if(i==0) begin
                r3[i] <= p_in[3];
            end else begin 
                r3[i] <= r3[i-1];
            end 
        end 

        for(i=0;i<5;i=i+1) begin
            if(i==0) begin
                r2[i] <= p_in[2];
            end else begin 
                r2[i] <= r2[i-1];
            end 
        end 

        for(i=0;i<6;i=i+1) begin
            if(i==0) begin
                r1[i] <= p_in[1];
            end else begin 
                r1[i] <= r1[i-1];
            end 
        end 

        for(i=0;i<7;i=i+1) begin
            if(i==0) begin
                r0[i] <= p_in[0];
            end else begin 
                r0[i] <= r0[i-1];
            end 
        end 
    end

    assign p_out[0] = r0[6];
    assign p_out[1] = r1[5];
    assign p_out[2] = r2[4];
    assign p_out[3] = r3[3];
    assign p_out[4] = r4[2];
    assign p_out[5] = r5[1];
    assign p_out[6] = r6;
    assign p_out[7] = p_in[7];

endmodule