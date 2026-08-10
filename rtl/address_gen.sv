`timescale 1ns / 1ps


module address_gen (
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

    output reg [31:0] ddr_addr,
    output reg [7:0] length
);


reg [31:0] current_weight_base;
reg [31:0] current_ifmap_base;
reg [31:0] current_ofmap_base;

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
end

endmodule







