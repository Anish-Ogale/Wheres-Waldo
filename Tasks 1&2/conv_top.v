`timescale 1ns / 1ps

module conv_top(
    input clk,
    input rst,
    input rx,
    output tx
);

    // UART instantiation wires
    wire [7:0] tx_data; 
    wire [7:0] rx_data;
    wire rx_ready;
    wire tx_busy;
    
    // Hardware block instantiation wires
    wire valid_out; 
    wire [7:0] pixel_out;
    
    // FIFO instantiation wires
    wire full; 
    wire empty;
    
    // Bridge Controller Registers
    reg [1:0] bridge_state;
    reg fifo_rd_en;
    reg uart_tx_start;

    UART u1(
        .clk(clk),
        .rst(rst),
        .rx(rx),
        .tx_data(tx_data),
        .tx_start(uart_tx_start), 
        .tx(tx),
        .rx_data(rx_data),
        .rx_ready(rx_ready),
        .tx_busy(tx_busy)
    );
    
    Morphology m1(
        .clk(clk),
        .rst(rst),
        .valid_in(rx_ready),
        .pixel_in(rx_data),
        .valid_out(valid_out),
        .pixel_out(pixel_out)
    );
    
   
    fifo f1(
        .clk(clk),
        .rst(rst),
        .wr_en(valid_out),
        .din(pixel_out),
        .full(full),
        .rd_en(fifo_rd_en),       
        .dout(tx_data),           
        .empty(empty)
    );

   
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            bridge_state  <= 2'd0;
            fifo_rd_en    <= 1'b0;
            uart_tx_start <= 1'b0;
        end else begin
        
            fifo_rd_en    <= 1'b0;
            uart_tx_start <= 1'b0;

            case (bridge_state)
                2'd0: begin 
                 
                    if (!empty && !tx_busy) begin
                        fifo_rd_en <= 1'b1;
                        bridge_state <= 2'd1;
                    end
                end
                
                2'd1: begin 
               
                    uart_tx_start <= 1'b1; 
                    bridge_state <= 2'd2;
                end
                
                2'd2: begin 
    
                    if (tx_busy) begin
                        bridge_state <= 2'd0;
                    end
                end
                
                default: bridge_state <= 2'd0;
            endcase
        end
    end

endmodule
