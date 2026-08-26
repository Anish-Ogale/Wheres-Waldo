`timescale 1ns / 1ps

module FSM #(
    parameter IDLE = 0,
    parameter LOAD_LAYER_PARAMS = 1,
    parameter LOAD_WEIGHTS = 2,
    parameter FILL_FMAP = 3,
    parameter CALC = 4,
    parameter DRAIN = 5,
    parameter POOL = 6,
    parameter WRITEBACK = 7,
    parameter NEXT_TILE_CHECK = 8,
    parameter LOAD_ARRAY = 9
)(
    input wire clk,
    input wire rst,
    input wire start,
    output reg swap,
    output reg valid_in,
    output wire padding,
    input wire [4:0] quantizer,
    output wire done,
    output wire req,
    input wire seq_done,
    output wire we,
    output wire [1:0] region_sel,
    output reg [3:0] layer_count,
    output reg [7:0] in_tile,
    output reg [7:0] out_tile,
    output reg [1:0] kx,
    output reg [1:0] ky,
    output reg [8:0] x,
    output reg [8:0] y,
    output reg [8:0] width_in_r,
    output reg [7:0] num_in_tiles_r,
    output reg kernel_size_r,
    output wire first_pass,
    output wire finalize,
    output wire pool_start,
    input wire pool_done,
    output wire pool_select,
    output reg relu_enable_r,
    output wire [17:0] fmap_read_addr,
    output wire [17:0] out_pixel_addr,
    output wire [9:0] weight_addr,
    output wire wb_rd_en,
    output wire weight_ena,
    output wire load_en
);

    reg [3:0] current_state;
    reg [3:0] next_state;

    localparam ARRAY_SIZE = 4'd8;
    reg [3:0] load_cnt;
    
    reg [8:0] width_in ;
    reg [10:0] channel_in;
    reg [10:0] channel_out;
    reg kernel_size;
    reg pool_enable;
    reg pool_stride;
    reg relu_enable;
    
    reg [7:0] num_in_tiles;
    reg [7:0] num_out_tiles;
    
    reg [10:0] channel_in_r;
    reg [10:0] channel_out_r;
    reg pool_enable_r;
    reg pool_stride_r;
    
    reg [7:0] num_out_tiles_r;

    reg fetched_in_tile_valid;
    reg [7:0] fetched_in_tile_r;

    reg [3:0] prev_state;

    reg req_issued;

    reg pool_req_issued;
    
    wire bounds_x = kernel_size_r && ( ( (x==0)&&(kx==0) ) || ( (x==width_in_r-1) && (kx==2) ) );
    wire bounds_y = kernel_size_r && ( ( (y==0)&&(ky==0) ) || ( (y==width_in_r-1) && (ky==2) ) );
    
    assign padding = (bounds_x || bounds_y);
    
    wire [8:0] x_actual = kernel_size_r ? (x + kx - 1) : x;
    wire [8:0] y_actual = kernel_size_r ? (y + ky - 1) : y;
    
    assign fmap_read_addr = y_actual*width_in_r + x_actual ;
    assign out_pixel_addr = y*width_in_r + x ;

    assign weight_addr = load_cnt;
    assign weight_ena = (current_state==LOAD_ARRAY) && (load_cnt < ARRAY_SIZE);
    assign load_en = (current_state==LOAD_ARRAY) && (load_cnt >= 4'd1);

    assign wb_rd_en = (current_state==WRITEBACK);
    
    wire [1:0] k_max = kernel_size_r ? 2'd2 : 2'd0;

    wire need_fetch = (!fetched_in_tile_valid) || (in_tile != fetched_in_tile_r);

    assign first_pass = (kx==0) && (ky==0) && (in_tile==0);
    assign finalize = (kx==k_max) && (ky==k_max) && (in_tile==num_in_tiles_r-1);

    assign done = (current_state==NEXT_TILE_CHECK) &&
                  (kx==k_max) && (ky==k_max) &&
                  (in_tile==num_in_tiles_r-1) && (out_tile==num_out_tiles_r-1) &&
                  (layer_count==4'd8);

    assign region_sel = (current_state==LOAD_WEIGHTS) ? 2'b00 :
                         (current_state==FILL_FMAP)   ? 2'b01 :
                         (current_state==WRITEBACK)   ? 2'b10 :
                                                        2'b00;

    assign we = (current_state==WRITEBACK);

    assign req = ((current_state==LOAD_WEIGHTS) && !req_issued) ||
                 ((current_state==FILL_FMAP) && need_fetch && !req_issued) ||
                 ((current_state==WRITEBACK) && !req_issued);

    assign pool_select = pool_stride_r;
    assign pool_start = (current_state==POOL) && !pool_req_issued;
    
    always @(*) begin 
        case(layer_count)
            4'd0 : begin
                width_in = 9'd416;
                channel_in = 11'd3;
                channel_out = 11'd16;
                kernel_size = 1'b1;
                pool_enable = 1'b1;
                pool_stride = 1'b0;
                relu_enable = 1'b1;
            end
            4'd1 : begin
                width_in = 9'd208;
                channel_in = 11'd16;
                channel_out = 11'd32;
                kernel_size = 1'b1;
                pool_enable = 1'b1;
                pool_stride = 1'b0;
                relu_enable = 1'b1;
            end
            4'd2 : begin
                width_in = 9'd104;
                channel_in = 11'd32;
                channel_out = 11'd64;
                kernel_size = 1'b1;
                pool_enable = 1'b1;
                pool_stride = 1'b0;
                relu_enable = 1'b1;
            end
            4'd3 : begin
                width_in = 9'd52;
                channel_in = 11'd64;
                channel_out = 11'd128;
                kernel_size = 1'b1;
                pool_enable = 1'b1;
                pool_stride = 1'b0;
                relu_enable = 1'b1;
            end
            4'd4 : begin
                width_in = 9'd26;
                channel_in = 11'd128;
                channel_out = 11'd256;
                kernel_size = 1'b1;
                pool_enable = 1'b1;
                pool_stride = 1'b0;
                relu_enable = 1'b1;
            end
            4'd5 : begin
                width_in = 9'd13;
                channel_in = 11'd256;
                channel_out = 11'd512;
                kernel_size = 1'b1;
                pool_enable = 1'b1;
                pool_stride = 1'b1;
                relu_enable = 1'b1;
            end
            4'd6 : begin
                width_in = 9'd13;
                channel_in = 11'd512;
                channel_out = 11'd1024;
                kernel_size = 1'b1;
                pool_enable = 1'b0;
                pool_stride = 1'b0;
                relu_enable = 1'b1;
            end
            4'd7 : begin
                width_in = 9'd13;
                channel_in = 11'd1024;
                channel_out = 11'd1024;
                kernel_size = 1'b1;
                pool_enable = 1'b0;
                pool_stride = 1'b0;
                relu_enable = 1'b1;
            end
            4'd8 : begin
                width_in = 9'd13;
                channel_in = 11'd1024;
                channel_out = 11'd125;
                kernel_size = 1'b0;
                pool_enable = 1'b0;
                pool_stride = 1'b0;
                relu_enable = 1'b0;
            end
            default : begin
                width_in = 9'd0;
                channel_in = 11'd0;
                channel_out = 11'd0;
                kernel_size = 1'b0;
                pool_enable = 1'b0;
                pool_stride = 1'b0;
                relu_enable = 1'b0;
            end
        endcase
        num_in_tiles = (channel_in + 11'd7)/11'd8;
        num_out_tiles = (channel_out + 11'd7)/11'd8;
    end
    
    always @(posedge clk) begin
        if(rst) begin
            load_cnt <= 4'd0;
        end else if(current_state==LOAD_ARRAY) begin
            if(load_cnt < ARRAY_SIZE) begin
                load_cnt <= load_cnt + 1'b1;
            end
        end else begin
            load_cnt <= 4'd0;
        end
    end

    always @(posedge clk) begin
        if(rst) begin
            current_state <= IDLE;  
        end else begin 
            current_state <= next_state; 
        end 
    end 

    always @(posedge clk) begin
        if(rst) begin
            prev_state <= IDLE;
            req_issued <= 1'b0;
        end else begin
            prev_state <= current_state;
            if(current_state != prev_state) begin
                req_issued <= 1'b0;
            end else if(current_state==LOAD_WEIGHTS || current_state==FILL_FMAP || current_state==WRITEBACK) begin
                req_issued <= 1'b1;
            end
        end
    end

    always @(posedge clk) begin
        if(rst) begin
            pool_req_issued <= 1'b0;
        end else if(current_state==POOL) begin
            pool_req_issued <= 1'b1;
        end else begin
            pool_req_issued <= 1'b0;
        end
    end

    always @(posedge clk) begin
        if(rst) begin
            fetched_in_tile_valid <= 1'b0;
            fetched_in_tile_r <= 8'd0;
            swap <= 1'b0;
        end else if(current_state==LOAD_LAYER_PARAMS) begin
            fetched_in_tile_valid <= 1'b0;
        end else if(current_state==FILL_FMAP && seq_done) begin
            fetched_in_tile_r <= in_tile;
            fetched_in_tile_valid <= 1'b1;
            swap <= ~swap;
        end
    end

    always @(posedge clk) begin
        if(rst) begin
            kx <= 2'd0;
            ky <= 2'd0;
            x <= 9'd0;
            y <= 9'd0;
            in_tile <= 8'd0;
            out_tile <= 8'd0;
            layer_count <= 4'd0;
        end else begin
            case(current_state) 
                IDLE : begin
                    kx <= 2'd0;
                    ky <= 2'd0;
                    x <= 9'd0;
                    y <= 9'd0;
                    in_tile <= 8'd0;
                    out_tile <= 8'd0;
                    valid_in <= 1'b0;
                end
                
                LOAD_LAYER_PARAMS : begin
                    width_in_r <= width_in;
                    channel_in_r <= channel_in;
                    channel_out_r <= channel_out;
                    kernel_size_r <= kernel_size;
                    pool_enable_r <= pool_enable;
                    pool_stride_r <= pool_stride;
                    relu_enable_r <= relu_enable;
                    num_in_tiles_r <= num_in_tiles;
                    num_out_tiles_r <= num_out_tiles;
                end
                
                LOAD_WEIGHTS : begin
                end
                
                FILL_FMAP : begin
                end
                
                CALC : begin
                    valid_in <= 1'b1;
                    if(x == width_in_r-1) begin
                        x <= 9'd0;
                        if(y == width_in_r-1) begin
                            y <= 9'd0;
                        end else begin
                            y <= y + 1'b1;
                        end
                    end else begin
                        x <= x + 1'b1;
                    end
                end
                
                DRAIN: begin
                    valid_in <= 1'b0;
                end
                
                POOL : begin
                end
                
                WRITEBACK : begin
                end
                
                NEXT_TILE_CHECK : begin
                    x <= 9'd0;
                    y <= 9'd0;
                    
                    if(kx == k_max) begin
                        kx <= 2'd0;
                        if(ky == k_max) begin
                            ky <= 2'd0;
                            if(in_tile == num_in_tiles_r-1) begin
                                in_tile <= 8'd0;
                                if(out_tile == num_out_tiles_r-1) begin
                                    out_tile <= 8'd0;
                                    if(layer_count == 4'd8) begin
                                        layer_count <= 4'd0;
                                    end else begin
                                        layer_count <= layer_count + 1'b1;
                                    end
                                end else begin
                                    out_tile <= out_tile + 1'b1;
                                end
                            end else begin
                                in_tile <= in_tile + 1'b1;
                            end
                        end else begin
                            ky <= ky + 1'b1;
                        end
                    end else begin
                        kx <= kx + 1'b1;
                    end
                end
            endcase
        end
    end
   
    always @(*) begin 
        next_state = current_state;
        case(current_state) 
            IDLE : begin
                if(start) begin
                    next_state = LOAD_LAYER_PARAMS ;
                end
            end 
            
            LOAD_LAYER_PARAMS : begin
                next_state = LOAD_WEIGHTS;
            end
            
            LOAD_WEIGHTS : begin
                if(seq_done) begin
                    next_state = FILL_FMAP;
                end
            end
            
            FILL_FMAP : begin
                if(!need_fetch) begin
                    next_state = LOAD_ARRAY;
                end else if(seq_done) begin
                    next_state = LOAD_ARRAY;
                end
            end
            
            LOAD_ARRAY : begin
                if(load_cnt==ARRAY_SIZE) begin
                    next_state = CALC;
                end
            end
            
            CALC : begin
                if((x==width_in_r-1)&&(y==width_in_r-1)) begin
                    next_state = DRAIN;
                end
            end
            
            DRAIN : begin
                if(finalize) begin
                    if(pool_enable_r) begin
                        next_state = POOL;
                    end else begin
                        next_state = WRITEBACK;
                    end
                end else begin
                    next_state = NEXT_TILE_CHECK;
                end
            end 
            
            POOL : begin
                if(pool_done) begin
                    next_state = WRITEBACK;
                end
            end
            
            WRITEBACK : begin
                if(seq_done) begin
                    next_state = NEXT_TILE_CHECK;
                end
            end
            
            NEXT_TILE_CHECK : begin
                if((kx==k_max)&&(ky==k_max)&&(in_tile==num_in_tiles_r-1)&&(out_tile==num_out_tiles_r-1)) begin
                    next_state = LOAD_LAYER_PARAMS;
                end else begin
                    next_state = LOAD_WEIGHTS;
                end
            end
        endcase
    end
endmodule