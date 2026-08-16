`timescale 1ns / 1ps
module weight_buffer #(
    parameter int DATA_WIDTH = 8,      
    parameter int ARRAY_SIZE = 8,       
    parameter int ADDR_WIDTH = 10       
)(
    input logic clk,
    input logic rst_n,
    
    input logic  we_A,       
    input logic [ADDR_WIDTH-1:0]  addr_A,     
    input logic [(DATA_WIDTH*ARRAY_SIZE)-1:0]   din_A,      
    
    input logic  ena_B,      
    input logic [ADDR_WIDTH-1:0]  addr_B,     
    output logic signed [DATA_WIDTH-1:0]   dout_B [0:ARRAY_SIZE-1] 
);

    (* ram_style = "block" *) logic [(DATA_WIDTH*ARRAY_SIZE)-1:0] ram [0:(1<<ADDR_WIDTH)-1];
    
    always_ff @(posedge clk) begin
        if (we_A) begin
            ram[addr_A] <= din_A;
        end
    end
    
    logic [(DATA_WIDTH*ARRAY_SIZE)-1:0] raw_read_data;

    always_ff @(posedge clk) begin
        if (ena_B) begin
            raw_read_data <= ram[addr_B];
        end
    end

    always_comb begin
        for (int i = 0; i < ARRAY_SIZE; i++) begin
            dout_B[i] = raw_read_data[(i*DATA_WIDTH) +: DATA_WIDTH];
        end
    end

endmodule
