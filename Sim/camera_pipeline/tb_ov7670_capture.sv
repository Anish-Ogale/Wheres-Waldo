`timescale 1ns / 1ps

module tb_ov7670_capture();

    parameter int ACTIVE_PIXELS_PER_LINE = 320;

    logic        pclk;
    logic        rst;
    logic        vsync;
    logic        href;
    logic [5:0]  d_in;
    logic [15:0] m_axis_tdata;
    logic        m_axis_tvalid;
    logic        m_axis_tready;
    logic        m_axis_tlast;
    logic        m_axis_tuser;

    ov7670_capture #(
        .ACTIVE_PIXELS_PER_LINE(ACTIVE_PIXELS_PER_LINE)
    ) dut (
        .pclk(pclk),
        .rst(rst),
        .vsync(vsync),
        .href(href),
        .d_in(d_in),
        .m_axis_tdata(m_axis_tdata),
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tready(m_axis_tready),
        .m_axis_tlast(m_axis_tlast),
        .m_axis_tuser(m_axis_tuser)
    );

    initial begin
        pclk = 0;
        forever #5 pclk = ~pclk;
    end

    initial begin
        rst = 1;
        vsync = 0;
        href = 0;
        d_in = 0;
        m_axis_tready = 1;
        
        #20 rst = 0;
        
        #50 vsync = 1;
        #30 vsync = 0;
        
        #50;
        
        for (int line = 0; line < 3; line++) begin
            href = 1;
            for (int p = 0; p < ACTIVE_PIXELS_PER_LINE * 2; p++) begin
                d_in = p[5:0];
                #10;
            end
            href = 0;
            #100;
        end
        
        #200 $finish;
    end

endmodule