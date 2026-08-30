`timescale 1ns / 1ps
module skewer #(
    parameter size = 8
)(
    input clk,
    input padding,
    input signed [(8*size)-1:0] pixel_in,
    output signed [(8*size)-1:0] pixel_out
);

    wire signed [7:0] p_in [0:size-1];
    wire signed [7:0] p_out [0:size-1];

    genvar g;
    generate
        for(g=0; g<size; g=g+1) begin : pack_unpack
            assign p_in[g] = padding ? 8'sd0 : pixel_in[(g*8) +: 8];
            assign pixel_out[(g*8) +: 8] = p_out[g];
        end
    endgenerate

    reg signed [7:0] r1;
    reg signed [7:0] r2 [0:1];
    reg signed [7:0] r3 [0:2];
    reg signed [7:0] r4 [0:3];
    reg signed [7:0] r5 [0:4];
    reg signed [7:0] r6 [0:5];
    reg signed [7:0] r7 [0:6];
    
    integer i;

    always @(posedge clk) begin
        
        r1 <= p_in[1];

        for(i=0;i<2;i=i+1) begin
            if(i==0) begin
                r2[i] <= p_in[2];
            end else begin 
                r2[i] <= r2[i-1];
            end 
        end 

        for(i=0;i<3;i=i+1) begin
            if(i==0) begin
                r3[i] <= p_in[3];
            end else begin 
                r3[i] <= r3[i-1];
            end 
        end 

        for(i=0;i<4;i=i+1) begin
            if(i==0) begin
                r4[i] <= p_in[4];
            end else begin 
                r4[i] <= r4[i-1];
            end 
        end 

        for(i=0;i<5;i=i+1) begin
            if(i==0) begin
                r5[i] <= p_in[5];
            end else begin 
                r5[i] <= r5[i-1];
            end 
        end 

        for(i=0;i<6;i=i+1) begin
            if(i==0) begin
                r6[i] <= p_in[6];
            end else begin 
                r6[i] <= r6[i-1];
            end 
        end 

        for(i=0;i<7;i=i+1) begin
            if(i==0) begin
                r7[i] <= p_in[7];
            end else begin 
                r7[i] <= r7[i-1];
            end 
        end 
    end

    assign p_out[0] = p_in[0];
    assign p_out[1] = r1;
    assign p_out[2] = r2[1];
    assign p_out[3] = r3[2];
    assign p_out[4] = r4[3];
    assign p_out[5] = r5[4];
    assign p_out[6] = r6[5];
    assign p_out[7] = r7[6];

endmodule