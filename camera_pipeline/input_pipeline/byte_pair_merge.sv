`timescale 1ns / 1ps

module byte_pair_merge (
    input  logic        pclk,
    input  logic        rst,
    input  logic        href,        // high = active line, byte on d_in is valid
    input  logic [5:0]  d_in,        // raw camera data bus, D7:D2 only
    output logic [15:0] pixel_out,   // merged RGB565 pixel {high_byte, low_byte}
    output logic        pixel_valid  // 1-cycle pulse when pixel_out is valid
);

    logic       byte_sel;       // 0 = expecting high byte, 1 = expecting low byte
    logic [7:0] high_byte_reg;

    wire [7:0] reconstructed_byte = {d_in, d_in[5:4]};

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
                    // first byte of this pixel (high byte)
                    high_byte_reg <= reconstructed_byte;
                    byte_sel      <= 1'b1;
                end else begin
                    // second byte of this pixel (low byte) -> pixel complete
                    pixel_out   <= {high_byte_reg, reconstructed_byte};
                    pixel_valid <= 1'b1;
                    byte_sel    <= 1'b0;
                end
            end
        end
    end

endmodule