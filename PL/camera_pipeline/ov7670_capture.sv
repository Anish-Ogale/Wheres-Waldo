`timescale 1ns / 1ps

module ov7670_capture #(
    parameter int ACTIVE_PIXELS_PER_LINE = 320
)(
    input  logic        pclk,
    input  logic        rst,
    input  logic        vsync,
    input  logic        href,
    input  logic [5:0]  d_in,        

    output logic [15:0] m_axis_tdata,
    output logic         m_axis_tvalid,
    input  logic         m_axis_tready,  
    output logic         m_axis_tlast,
    output logic         m_axis_tuser
);

    logic [15:0] pixel_data;
    logic        pixel_valid;
    logic        sof_pulse;

    byte_pair_merge u_byte_pair_merge (
        .pclk        (pclk),
        .rst         (rst),
        .href        (href),
        .d_in        (d_in),
        .pixel_out   (pixel_data),
        .pixel_valid (pixel_valid)
    );

    frame_sync u_frame_sync (
        .clk   (pclk),
        .rst   (rst),
        .vsync (vsync),
        .sof   (sof_pulse)
    );

    logic href_d;
    always_ff @(posedge pclk) begin
        if (rst) href_d <= 1'b0;
        else     href_d <= href;
    end

    wire line_start = href & ~href_d;   

    localparam int COL_W = $clog2(ACTIVE_PIXELS_PER_LINE);
    logic [COL_W-1:0] pixel_col;

    always_ff @(posedge pclk) begin
        if (rst) begin
            pixel_col <= '0;
        end else if (line_start) begin
            pixel_col <= '0;
        end else if (pixel_valid) begin
            pixel_col <= pixel_col + 1'b1;
        end
    end

    logic sof_pending;
    always_ff @(posedge pclk) begin
        if (rst) begin
            sof_pending <= 1'b0;
        end else if (sof_pulse) begin
            sof_pending <= 1'b1;
        end else if (pixel_valid) begin
            sof_pending <= 1'b0;
        end
    end
    
    always_ff @(posedge pclk) begin
        if (rst) begin
            m_axis_tdata  <= 16'h0000;
            m_axis_tvalid <= 1'b0;
            m_axis_tlast  <= 1'b0;
            m_axis_tuser  <= 1'b0;
        end else begin
            m_axis_tdata  <= pixel_data;
            m_axis_tvalid <= pixel_valid;
            m_axis_tlast  <= pixel_valid && (pixel_col == ACTIVE_PIXELS_PER_LINE - 1);
            m_axis_tuser  <= pixel_valid && sof_pending;
        end
    end

endmodule