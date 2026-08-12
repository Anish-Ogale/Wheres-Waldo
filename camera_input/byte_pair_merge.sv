`timescale 1ns / 1ps

module byte_pair_merge (
    input  logic        pclk,
    input  logic        rst,
    input  logic        href,       
  input  logic [7:0]  d_in,        
    output logic [15:0] pixel_out,   
    output logic        pixel_valid  
);

    logic       byte_sel;      
    logic [7:0] high_byte_reg;

    always_ff @(posedge pclk) begin
        if (rst) begin
            byte_sel      <= 1'b0;
            high_byte_reg <= 8'h00;
            pixel_out     <= 16'h0000;
            pixel_valid   <= 1'b0;
        end else begin
            pixel_valid <= 1'b0;  

            if (!href) begin
                byte_sel <= 1'b0;
            end else begin
                if (byte_sel == 1'b0) begin
                    high_byte_reg <= d_in;
                    byte_sel      <= 1'b1;
                end else begin
                    pixel_out   <= {high_byte_reg, d_in};
                    pixel_valid <= 1'b1;
                    byte_sel    <= 1'b0;
                end
            end
        end
    end

endmodule
