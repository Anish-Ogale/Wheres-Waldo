`timescale 1ns / 1ps

module frame_sync (
    input  logic clk,
    input  logic rst,
    input  logic vsync,
    output logic sof     
);

    logic vsync_d;

    always_ff @(posedge clk) begin
        if (rst) begin
            vsync_d <= 1'b0;
        end else begin
            vsync_d <= vsync;
        end
    end

    assign sof = vsync_d & ~vsync;  

endmodule
