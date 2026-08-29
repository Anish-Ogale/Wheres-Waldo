`timescale 1ns / 1ps

module frame_sync (
    input  logic clk,
    input  logic rst,
    input  logic vsync,
    output logic sof     
);

    logic vsync_d1, vsync_d2;

    always_ff @(posedge clk) begin
        if (rst) begin
            vsync_d1 <= 1'b0;
            vsync_d2 <= 1'b0;
        end else begin
            vsync_d1 <= vsync;
            vsync_d2 <= vsync_d1;
        end
    end

    assign sof = vsync_d2 & ~vsync_d1;  

endmodule