`timescale 1ns / 1ps

module tb_top_uart;

    // Standard clock and reset
    reg clk;
    reg rst;

    // Signals to control the PC Emulator UART
    reg [7:0] pc_tx_data;
    reg pc_tx_start;
    wire pc_tx;
    wire [7:0] pc_rx_data;
    wire pc_rx_ready;
    wire pc_tx_busy;


    wire top_rx;
    wire top_tx;



    assign top_rx = pc_tx; 
    

    assign pc_rx = top_tx;  



    top_uart uut (
        .clk(clk),
        .rst(rst),
        .rx(top_rx),
        .tx(top_tx)
    );

    
    UART pc_emulator (
        .clk(clk),
        .rst(rst),
        .rx(pc_rx),
        .tx_data(pc_tx_data),
        .tx_start(pc_tx_start),
        .tx(pc_tx),
        .rx_data(pc_rx_data),
        .rx_ready(pc_rx_ready),
        .tx_busy(pc_tx_busy)
    );


    initial begin
        clk = 0;
        forever #10 clk = ~clk; 
    end

    
    initial begin
    
        #5000000; 
        $display("FATAL ERROR: Simulation timed out. PC never received the echo.");
        $finish;
    end

    initial begin
    
        rst = 1;
        pc_tx_data = 8'h00;
        pc_tx_start = 0;


        #100;
        rst = 0;
        #100;

        
        $display("Starting the Echo Server round-trip test...");
        pc_tx_data = 8'h5A; 
        
        
        @(posedge clk);
        pc_tx_start = 1;
        @(posedge clk);
        pc_tx_start = 0;

    
        wait(pc_rx_ready == 1'b1);
        
        
        @(posedge clk);
        
    
        if (pc_rx_data == pc_tx_data) begin
            $display("SUCCESS: PC received the exact echo (8'h%h)!", pc_rx_data);
        end else begin
            $display("ERROR: PC sent 8'h%h but received 8'h%h.", pc_tx_data, pc_rx_data);
        end
        
        
        #1000;
        $finish;
    end
    
    
    initial begin
        $dumpfile("echo_server_tb.vcd");
        $dumpvars; 
    end

endmodule