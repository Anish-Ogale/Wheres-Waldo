`timescale 1ns / 1ps

module address_gen #(
    localparam accumulator_base = 32'h115C000,
    localparam burst_limit = 8'd255
)(
    input [3:0] layer_count,
    input [7:0] in_tile,
    input [7:0] out_tile,
    input [1:0] kx,
    input [1:0] ky,
    input [8:0] x,
    input [8:0] y,
    input [7:0] num_in_tiles,
    input [8:0] width_in,
    input [1:0] region_sel,

    input kernel_size,
    input [4:0] row_idx,
    input [8:0] beat_offset,
    
    output reg more_beats,
    output reg [31:0] ddr_addr,
    output reg [7:0] length,
    output reg [31:0] bram_offset,
    output reg more_rows
);  

reg [31:0] current_weight_base;
reg [31:0] current_ifmap_base;
reg [31:0] current_ofmap_base;

wire [16:0] tile_index = (out_tile*num_in_tiles) + in_tile;
wire [3:0] taps_per_tile = (kernel_size)? 9 : 1;
wire [3:0] tap_index = ky*3 + kx;
wire [31:0] weight_offset = (tile_index*taps_per_tile + tap_index) * 32'd64;


reg pool_enable;
reg pool_stride;
reg [8:0] width_out;

always @(*) begin
    case(layer_count)
        4'd0, 4'd1, 4'd2, 4'd3, 4'd4: begin pool_enable = 1; pool_stride = 1; end
        4'd5: begin pool_enable = 1; pool_stride = 0; end
        default: begin pool_enable = 0; pool_stride = 0; end
    endcase
    
    if (pool_enable && pool_stride) width_out = width_in >> 1;
    else width_out = width_in;
end

always @(*) begin
    case(layer_count) 
        4'd0 : begin current_weight_base = 32'h000000; current_ofmap_base = 32'hFA0000; current_ifmap_base = 32'hF21000; end
        4'd1: begin current_weight_base = 32'h000480; current_ofmap_base = 32'h1049000; current_ifmap_base = 32'hFA0000; end
        4'd2: begin current_weight_base = 32'h001680; current_ofmap_base = 32'h109E000; current_ifmap_base = 32'h1049000; end
        4'd3: begin current_weight_base = 32'h005E80; current_ofmap_base = 32'h10C9000; current_ifmap_base = 32'h109E000; end
        4'd4: begin current_weight_base = 32'h017E80; current_ofmap_base = 32'h10DF000; current_ifmap_base = 32'h10C9000; end
        4'd5: begin current_weight_base = 32'h05FE80; current_ofmap_base = 32'h10EA000; current_ifmap_base = 32'h10DF000; end
        4'd6: begin current_weight_base = 32'h17FE80; current_ofmap_base = 32'h1100000; current_ifmap_base = 32'h10EA000; end
        4'd7: begin current_weight_base = 32'h5FFE80; current_ofmap_base = 32'h112B000; current_ifmap_base = 32'h1100000; end
        4'd8: begin current_weight_base = 32'hEFFE80; current_ofmap_base = 32'h1156000; current_ifmap_base = 32'h112B000; end
        default: begin current_weight_base = 32'h000000; current_ofmap_base = 32'h000000; current_ifmap_base = 32'h000000; end
    endcase

    more_beats = 1'b0;
    more_rows = 1'b0;
    ddr_addr = 0;
    length = 0;
    bram_offset = 0;

    case(region_sel)
        2'b00: begin  // Weights
            ddr_addr = current_weight_base + weight_offset;
            length = 8'd8; // 8 beats for weight
            bram_offset = 0;
            more_rows = 1'b0; 
        end
        2'b01: begin // IFM

            if (y + row_idx < width_in) begin
                ddr_addr = current_ifmap_base + (((y + row_idx)*width_in + x) * 8);
                if (width_in - x < 9'd18) length = width_in - x;
                else length = 8'd18;
            end else begin
                length = 0; // Out of bounds row
            end
            bram_offset = row_idx * 18;
            more_rows = (row_idx < 17);
        end
        2'b10: begin // OFM writeback
           
            reg [4:0] active_w;
            reg [4:0] active_h;
            reg [8:0] out_x;
            reg [8:0] out_y;
            
            if (width_in - x < 16) active_w = width_in - x; else active_w = 16;
            if (width_in - y < 16) active_h = width_in - y; else active_h = 16;
            
            if (pool_enable && pool_stride) begin
                active_w = active_w >> 1;
                active_h = active_h >> 1;
                out_x = x >> 1;
                out_y = y >> 1;
            end else if (pool_enable && !pool_stride) begin
                active_w = active_w - 1;
                active_h = active_h - 1;
                out_x = x;
                out_y = y;
            end else begin
                out_x = x;
                out_y = y;
            end

            if (row_idx < active_h) begin
                ddr_addr = current_ofmap_base + (((out_y + row_idx)*width_out + out_x) * 8);
                length = active_w;
            end else begin
                length = 0;
            end
            
           
            bram_offset = row_idx * active_w;
            more_rows = (row_idx < active_h - 1);
        end
        default: begin
        end
    endcase
end

endmodule