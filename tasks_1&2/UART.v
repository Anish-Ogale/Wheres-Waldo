`timescale 1ns / 1ps

module UART #(
    parameter TX_IDLE = 0, TX_START = 1, TX_DATA = 2, TX_STOP = 3, 
    parameter RX_IDLE = 0, RX_START = 1, RX_DATA = 2, RX_STOP = 3
) (
    input clk,
    input rst,
    input rx,
    input [7:0] tx_data,
    input tx_start,
    output reg tx,
    output reg [7:0] rx_data,
    output reg rx_ready,
    output reg tx_busy
);

   
    reg [7:0] tx_shiftreg;
    reg [12:0] rx_count;
    reg [12:0] tx_count;
    reg [7:0] rx_shiftreg;
    reg [2:0] rx_bit_count;
    reg [1:0] tx_state;
    reg [1:0] rx_state;
    reg [2:0] tx_bit_count;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            tx_state <= TX_IDLE;
            tx <= 1'b1;
            tx_busy <= 1'b0;
            tx_count <= 13'd0;
            tx_bit_count <= 3'd0;
        end else begin 
            case (tx_state)
                TX_IDLE : begin
                    tx <= 1'b1;
                    tx_count <= 13'd0;
                    if (tx_start) begin
                        tx_shiftreg <= tx_data;
                        tx_busy <= 1'b1;
                        tx_state <= TX_START;
                    end 
                end
                
                TX_START: begin
                    tx <= 1'b0;
                    if (tx_count < 13'd5207) begin
                        tx_count <= tx_count + 13'd1;
                    end else begin
                        tx_count <= 13'd0;
                        tx_state <= TX_DATA;
                        tx_bit_count <= 3'd0;
                    end
                end
                
                TX_DATA: begin
                    tx <= tx_shiftreg[0];
                    if (tx_count < 13'd5207) begin
                        tx_count <= tx_count + 13'd1;
                    end else begin
                        tx_count <= 13'd0;
                        tx_shiftreg <= tx_shiftreg >> 1'b1;
                        
                        if (tx_bit_count == 3'd7) begin
                            tx_state <= TX_STOP;
                        end else begin
                            tx_bit_count <= tx_bit_count + 3'd1;
                        end
                    end
                end
                
                TX_STOP : begin
                    tx <= 1'b1;
                    if (tx_count < 13'd5207) begin
                        tx_count <= tx_count + 13'd1;
                    end else begin
                        tx_count <= 13'd0;
                        tx_busy <= 1'b0;
                        tx_state <= TX_IDLE;
                    end
                end
                
                default : tx_state <= TX_IDLE;
            endcase
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rx_state <= RX_IDLE;
            rx_ready <= 1'b0;
            rx_count <= 13'd0;
            rx_bit_count <= 3'd0;
        end else begin
            case(rx_state) 
                RX_IDLE : begin
                    rx_ready <= 1'b0;
                    if (rx == 1'b0) begin
                        rx_count <= 13'd0;
                        rx_state <= RX_START;
                    end
                end
                
                RX_START : begin
                    if (rx_count < 13'd2603) begin
                        rx_count <= rx_count + 13'd1;
                    end else begin
                        rx_count <= 13'd0;
                        if (rx == 1'b0) begin
                            rx_bit_count <= 3'd0;
                            rx_state <= RX_DATA;
                        end else begin 
                            rx_state <= RX_IDLE;
                        end
                    end
                end
                
                RX_DATA: begin
                    if (rx_count < 13'd5207) begin
                        rx_count <= rx_count + 13'd1;
                    end else begin
                        rx_count <= 13'd0; 
                        rx_shiftreg <= {rx, rx_shiftreg[7:1]};

                        if (rx_bit_count == 3'd7) begin
                            rx_state <= RX_STOP;
                        end else begin
                            rx_bit_count <= rx_bit_count + 3'd1;
                        end
                    end       
                end
                
                RX_STOP : begin
                    if (rx_count < 13'd5207) begin
                        rx_count <= rx_count + 13'd1;
                    end else begin
                        rx_count <= 13'd0; 
                        if (rx == 1'b1) begin
                            rx_data <= rx_shiftreg; 
                            rx_ready <= 1'b1;     
                        end
                        rx_state <= RX_IDLE;
                    end
                end

                default: begin
                    rx_state <= RX_IDLE;
                end
            endcase
        end
    end
endmodule
              
            
              
            
    
    
    
                
                
        
        
       

     
     


