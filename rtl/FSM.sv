`timescale 1ns / 1ps
module FSM#(

        localparam IDLE = 0,
        localparam LOAD_LAYER_PARAMS = 1,
        localparam LOAD_WEIGHTS = 2,
        localparam FILL_FMAP = 3,
        localparam CALC = 4,
        localparam DRAIN = 5,
        localparam POOL = 6,
        localparam WRITEBACK = 7,
        localparam NEXT_TILE_CHECK = 8

)(
        input clk,
        input rst,
        input start,     //starts the fpga fabric
        
        output reg weight_load_en,
        output reg [19:0] weight_addr,   
        output reg swap,   // swap fmap buffer banks
        output reg valid_in,    // starts the sys array
        output padding,  
        input [4:0] quantizer,
        input fmap_load_done,
        
        
        output done, 
        output reg dma_ready,   //signal indicating that the systolic array is done processing elements
        input dma_ack
       
    );

    reg [3:0] current_state;  // state registers 
    reg [3:0] next_state;     // state registers
    
    
    reg [1:0] kx;    //kernel counters
    reg [1:0] ky;    //kernel counters
    
    
    reg [8:0] x;    // image size counter
    reg [8:0] y;    // image size counter
    
    reg [7:0] in_tile;
    reg [7:0] out_tile;
    
    reg [3:0] layer_count;
  
  
  //---------------------------
  // Layer data table 
  
  reg [8:0] width_in ;     //input image width
  reg [10:0] channel_in;   //input channel number
  reg [10:0] channel_out;
  reg kernel_size;    // 0 if size =1, else 1
  reg pool_enable;
  reg pool_stride;
  reg relu_enable;
  
  reg [7:0] num_in_tiles;
  reg [7:0] num_out_tiles;
  reg [7:0] weights_per_tile;
  
  reg [8:0] width_in_r ;
  reg [10:0] channel_in_r;
  reg [10:0] channel_out_r;
  reg kernel_size_r;
  reg pool_enable_r;
  reg pool_stride_r;
  reg relu_enable_r;
  
  reg [7:0] num_in_tiles_r;
  reg [7:0] num_out_tiles_r;
  reg [7:0] weights_per_tile_r;
  
    
  //---------------------------
  
    
    wire bounds_x = ( ( (x==0)&&(kx==0) ) || ( (x==width_in_r-1) && (kx==2) ) );
    wire bounds_y = ( ( (y==0)&&(ky==0) ) || ( (y==width_in_r-1) && (ky==2) ) );
    
    
    assign padding = (bounds_x || bounds_y);
    
    wire [8:0] x_actual = x + kx -1 ;
    wire [8:0] y_actual = y + ky -1;
    
    
    wire [17:0] fmap_read_addr = y_actual*width_in_r + x_actual ;
    
    wire [1:0] k_max = kernel_size_r ? 2'd2 : 2'd0;
  
  
  
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
    weights_per_tile = ((kernel_size==0)?8'd1:8'd9)*8'd8*8'd8;
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
            kx <= '0;
            ky <= '0;
            x <= '0;
            y <= '0;
            in_tile <= '0;
            out_tile <= '0;
            layer_count <= '0;
            
        end else begin
            case(current_state) 
                IDLE : begin
                
                         kx <= '0;
                         ky <= '0;
                         x <= '0;
                         y <= '0;
                         in_tile <= '0;
                         out_tile <= '0;
                         weight_addr <= '0;
                         weight_load_en <= '0;
                         valid_in <= '0;
                         swap <= '0;
                         dma_ready <= '0;
                         
                
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
                weights_per_tile_r <= weights_per_tile;
                weight_addr <= '0;
                
                end
                
                LOAD_WEIGHTS : begin
                weight_load_en <= 1'b1;
                weight_addr <= weight_addr + 1'b1;
                
                
                
                end
                
                FILL_FMAP : begin
                weight_load_en <= '0;
                
                
                end
                
                
                CALC : begin
                valid_in <= 1'b1;
                
                
                
                
                if(x == width_in_r-1) begin
                    x <= '0;
                    if(y == width_in_r-1) begin
                        y <= '0;
                    end else begin
                        y <= y + '1;
                    end
                end else begin
                    x <= x+ '1;
                end
                
                end
                
                DRAIN: begin
                valid_in <= '0;
                
                
                
                
                end
                
                POOL : begin
                
                
                end
                
                WRITEBACK : begin
                dma_ready <= 1'b1;
                
                end
                
                NEXT_TILE_CHECK : begin
                x <= '0;
                y <= '0;
                weight_addr <= '0;
                dma_ready <= '0;
                
                if(kx == k_max) begin
                    kx <= '0;
                    if(ky == k_max) begin
                        ky <= '0;
                        if(in_tile == num_in_tiles_r-1) begin
                            in_tile <= '0;
                            swap <= ~swap;
                            if(out_tile == num_out_tiles_r-1) begin
                                out_tile <= '0;
                                if(layer_count == 4'd8) begin
                                    layer_count <= '0;
                                end else begin
                                    layer_count <= layer_count + 1'b1;
                                end
                            end else begin
                                out_tile <= out_tile + 1'b1;
                            end
                        end else begin
                            in_tile <= in_tile + 1'b1;
                            swap <= ~swap;
                        end
                    end else begin
                        ky <= ky + '1;
                    end
                end else begin
                    kx <= kx + '1;
                end
                
                end
                
                
           endcase
       end
   end
   
   
   
   always @(*) begin    //state transition combinational block
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
            
            if(weight_addr == weights_per_tile_r - 1'b1) begin
              
                next_state = FILL_FMAP;
            end
            
            
            
            end
            
            FILL_FMAP : begin
            if(fmap_load_done) begin
                next_state = CALC;
            end
            
            
            end
            
            CALC : begin
            
            if((x==width_in_r-1)&&(y==width_in_r-1)) begin
                next_state = DRAIN;
            
            
            end
            end
            
            
            DRAIN : begin
            
            if(pool_enable_r) begin
                next_state = POOL;
            end else begin
                next_state = WRITEBACK;
            end
            
            end 
            
            POOL : begin
            
            next_state = WRITEBACK;
            
            end
            
            WRITEBACK : begin
            
            if(dma_ack) begin
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


