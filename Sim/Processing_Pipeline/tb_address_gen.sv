`timescale 1ns / 1ps

module tb_address_gen;

    reg [3:0] layer_count;
    reg [7:0] in_tile;
    reg [7:0] out_tile;
    reg [1:0] kx;
    reg [1:0] ky;
    reg [8:0] x;
    reg [8:0] y;
    reg [7:0] num_in_tiles;
    reg [8:0] width_in;
    reg [1:0] region_sel; 
    reg kernel_size;  
    reg [8:0] beat_offset;
    
    wire more_beats;
    wire [31:0] ddr_addr;
    wire [7:0] length;

    address_gen dut (
        .layer_count(layer_count),
        .in_tile(in_tile),
        .out_tile(out_tile),
        .kx(kx),
        .ky(ky),
        .x(x),
        .y(y),
        .num_in_tiles(num_in_tiles),
        .width_in(width_in),
        .region_sel(region_sel),
        .kernel_size(kernel_size),
        .beat_offset(beat_offset),
        .more_beats(more_beats),
        .ddr_addr(ddr_addr),
        .length(length)
    );

    initial begin
        $display("--------------------------------------------------");
        $display("--- Starting Address Generator Simulation ---");
        $display("--------------------------------------------------");

        layer_count = 0; in_tile = 0; out_tile = 0; kx = 0; ky = 0;
        x = 0; y = 0; num_in_tiles = 1; width_in = 100; 
        region_sel = 0; kernel_size = 1; beat_offset = 0;
        
        #10; 
        $display("Time: %0t | TEST 1 (Weight)      | Layer: %d | Addr: %h | Len: %d | More: %b", $time, layer_count, ddr_addr, length, more_beats);
        
        layer_count = 4'd1;
        region_sel  = 2'b01;
        width_in    = 9'd300; 
        
        #10;
        $display("Time: %0t | TEST 2 (Ifmap)       | Layer: %d | Addr: %h | Len: %d | More: %b", $time, layer_count, ddr_addr, length, more_beats);
        
        layer_count = 4'd2;
        region_sel  = 2'b11;
        width_in    = 9'd100; 
        
        #10;
        $display("Time: %0t | TEST 3 (Accumulator) | Layer: %d | Addr: %h | Len: %d | More: %b", $time, layer_count, ddr_addr, length, more_beats);
        
        $display("--------------------------------------------------");
        $display("--- Simulation Complete ---");
        $display("--------------------------------------------------");
        
        $finish; 
    end

endmodule