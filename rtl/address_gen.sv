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
    input [1:0] region_sel, // 00 -> weight, 01-> ifmap , 10 -> ofmap , 11 -> accumulator


    input kernel_size,  //high when kernel is 3x3, low when kernel is 1x1
    input [8:0] beat_offset,
    
    output reg more_beats,
    output reg [31:0] ddr_addr,
    output reg [7:0] length
);  


reg [31:0] current_weight_base;
reg [31:0] current_ifmap_base;
reg [31:0] current_ofmap_base;
reg [8:0] remaining_width;


reg [31:0] ifmap_offset;
reg [31:0] ofmap_offset;
reg [31:0] accum_offset;

wire [16:0] tile_index;
wire [3:0] taps_per_tile;
wire [3:0] tap_index;
wire [31:0] weight_offset;


assign tile_index = (out_tile*num_in_tiles) + in_tile;
assign taps_per_tile = (kernel_size)?9:1;
assign tap_index = ky*3 + kx;
assign weight_offset = (tile_index*taps_per_tile + tap_index) * 32'd64;


always @(*) begin

    case(layer_count) 
        4'd0 : begin
            current_weight_base = 32'h000000;
            current_ofmap_base = 32'hFA0000;
            current_ifmap_base = 32'hF21000;


        end

        4'd1: begin
            current_weight_base = 32'h000480;
            current_ofmap_base = 32'h1049000;
            current_ifmap_base = 32'hFA0000;

        end

        4'd2: begin
            current_weight_base = 32'h001680;
            current_ofmap_base = 32'h109E000;
            current_ifmap_base = 32'h1049000;
        end
            
        4'd3: begin
            current_weight_base = 32'h005E80;
            current_ofmap_base = 32'h10C9000;
            current_ifmap_base = 32'h109E000;           
        end

        4'd4: begin
            current_weight_base = 32'h017E80;
            current_ofmap_base = 32'h10DF000;
            current_ifmap_base = 32'h10C9000;
        end

        4'd5: begin
            current_weight_base = 32'h05FE80;
            current_ofmap_base = 32'h10EA000;
            current_ifmap_base = 32'h10DF000;
        end

        4'd6: begin
            current_weight_base = 32'h17FE80;
            current_ofmap_base = 32'h1100000;
            current_ifmap_base = 32'h10EA000;
        end

        4'd7: begin
            current_weight_base = 32'h5FFE80;
            current_ofmap_base = 32'h112B000;
            current_ifmap_base = 32'h1100000;
        end

        4'd8: begin
            current_weight_base = 32'hEFFE80;
            current_ofmap_base = 32'h1156000;
            current_ifmap_base = 32'h112B000;
        end

        default: begin
            current_ifmap_base = 32'h000000;
            current_ofmap_base = 32'h000000;
            current_weight_base = 32'h000000;
        end
    endcase


    remaining_width = width_in - x - beat_offset;
     ifmap_offset = ((y*width_in) + x + beat_offset)*8;
     ofmap_offset = ((y*width_in) + x+ beat_offset)*8;
    accum_offset = ((y*width_in) + x+ beat_offset)*32;
    


     if(remaining_width > burst_limit) begin
         length = burst_limit;
            more_beats = 1'b1;
        end else begin
            length = remaining_width;  
            more_beats = 1'b0;
        end

     case(region_sel)
        2'b00: begin  //weight
            ddr_addr = current_weight_base + weight_offset;
            more_beats = '0;
            length = 8'd8;
        end
        2'b01: begin //ifmap
            ddr_addr = current_ifmap_base + ifmap_offset;
        end
        2'b10: begin    //ofmap
            ddr_addr = current_ofmap_base + ofmap_offset;
        end
        2'b11: begin    //accumulator
            ddr_addr = accumulator_base + accum_offset;
        end
        default : begin
            ddr_addr = '0;
        end
    

    endcase
end



endmodule



 









