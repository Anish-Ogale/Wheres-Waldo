`timescale 1ns / 1ps

module top_uart(
        input clk,
        input rst,
        input rx,
        output tx
    );
    
    reg [7:0] tx_data;
    reg tx_start;
    wire [7:0] rx_data;
    wire rx_ready;
    wire tx_busy;
    
    reg [7:0] stored;
    reg send_pending;
    
    
    UART u1(.clk(clk),.rst(rst),.rx(rx),.tx_data(tx_data),.tx_start(tx_start),.tx(tx),.rx_data(rx_data),.rx_ready(rx_ready),.tx_busy(tx_busy));
    
    always @(posedge clk) begin
    
    
        if(rst) begin
            stored <= 8'd0;
            send_pending <= 1'b0;
            tx_start <= 1'b0;
            tx_data <= 8'd0;
        end else begin
    
        if(rx_ready) begin
            stored <= rx_data;
            send_pending <= 1'b1;
        end 
        
        tx_data <= stored;
        if((~tx_busy)&(send_pending)) begin
            tx_start <= 1'b1;
            send_pending <= 1'b0;
            end else begin
            tx_start <= 1'b0;
            end
            
        end
        end
              
          
    
    
endmodule
