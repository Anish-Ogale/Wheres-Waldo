`timescale 1ns / 1ps

module AXI_Master#(

    localparam IDLE = 0,
    localparam SETUP_WRITE = 1,
    localparam WRITE_DATA =2,
    localparam WAIT_BRESP = 3,
    localparam SETUP_READ = 4,
    localparam READ_DATA = 5
    

)(

//---------------------------------------------------------

            //control interface
            input clk,
            input rst,
            input req,      // requests memory transaction
            input we,       // 1 for writing, 0 for reading
            input [31:0] ddr_addr,  // address in the ddr memory
            input [31:0] local_addr,   //address in the BRAM
            input [7:0] length,     //number of values to transfer in a burst
            output  reg ack,          // signal that goes high when a transaction is finished
            
//--------------------------------------------------------

            //axi write address channel
            input awready,      //sgnal controlled by slave when it is ready to recieve
            output reg [7:0] awlen,     //
            output reg awvalid,             //high when awlen and awaddr are valid
            output reg [31:0] awaddr,       // address to be written at
            
//-------------------------------------------------------
            //write data channel
            
            input wready,       //slave asserts high when it is ready to accept data
            output  [63:0] wdata,        //data to be written to the ddr3
            output reg [7:0] wstrb,         //
            output  wlast,           // high on the last burst
            output reg wvalid,       //goes high when wdata is valid
            
            
//--------------------------------------------------------
            //write response channel
            
            
            input [1:0] bresp,      //current status of the write
            input bvalid,       //asserted high by slave when response is valid
            output reg bready,      //signaled high by master when it is ready to recieve response
            
            
//--------------------------------------------------------
            //read data channel
            
            
            input [63:0] rdata,     //data coming from ddr3
            input rlast,           //signals high when the last burst is sent
            input rvalid,           //slave asserts high when rdata is valid
            output reg rready,          //master asserts hoigh when it is ready to recieve data
            
//----------------------------------------------------------

            //read address channel
            
            output reg [31:0] araddr,       //address where ddr3 is read from           
            output reg [7:0] arlen,         //length of address
            output reg arvalid,             //goes high when araddr is valid
            input arready,          //goes high when ddr3 is ready to accept data address 
  
//------------------------------------------------------------------
  
  //bram interface (connects to the accumulator)
  output  [63:0] bram_wdata, 	//data from ddr3, written to bram
  output  bram_we,					//write enable signal
  input [63:0] bram_rdata,
  output  [31:0] bram_addr//data read from bram, sent to ddr3
             
            
            
                 
            
            
            
            
            
    );
    
    
    
    
  reg [2:0] next_state;
  reg [2:0] current_state;
  reg [7:0] burst_count;
    
  
  
  assign bram_addr = local_addr + burst_count;
assign wdata = bram_rdata;
assign bram_wdata = rdata;
  assign bram_we = (current_state == READ_DATA) && rvalid && rready;
  assign wlast = (current_state == WRITE_DATA) && (burst_count == (length - 1));
    
    
   
    
    always @(posedge clk) begin 
        if(rst) begin
            awvalid <= '0;
            arvalid <= '0;
            wvalid <= '0;
            current_state <= IDLE;
          	burst_count <= '0;
          	bready <= '0;
          rready <= '0;
          
          
        end else begin
          current_state <= next_state;
          case(next_state) 
            IDLE : begin
              awvalid <= '0;
            arvalid <= '0;
            wvalid <= '0;
              	burst_count <= '0;
          	bready <= '0;
          rready <= '0;
              
              
            end
            
            SETUP_WRITE : begin
              awvalid <= '1;
              awaddr <= ddr_addr;
              awlen <= length - 1;
              
              
            end
            
            WRITE_DATA : begin
              awvalid <= '0;
              wvalid <= '1;
              wstrb <= 8'hFF;
              if(wready&&wvalid) begin
                burst_count <= burst_count + 1'b1;
                
               
              end
            
              
            end
            
            WAIT_BRESP : begin
              wvalid <= '0;
              bready <= '1;
              
              
            end
            
            SETUP_READ : begin
              arvalid <= '1;
              araddr <= ddr_addr;
              arlen <= length - 1;
             
              
              
            end
            
            READ_DATA : begin
              arvalid <= '0;
              rready <= 1'b1;
              if(rvalid&&rready)begin
                burst_count <= burst_count + 1'b1;
                
                
              
                end
                
              
            end
                endcase
        end
        
        
    end
    
    
    
    always @(*) begin
      ack = '0;
      next_state = current_state;
    
    case(current_state)
        IDLE : begin
          ack = '0;
            if(req) begin
                if(we) begin
                    next_state = SETUP_WRITE;
                end else begin
                    next_state = SETUP_READ;
                end
            end
        end
        SETUP_WRITE : begin
          if(awready) begin
            next_state = WRITE_DATA;
          end
          
        
        
        
        
        
        end
        
        WRITE_DATA : begin
          if(wready) begin
            if(wlast) begin
              next_state = WAIT_BRESP;
            end
          end
        
        
        end
        
        
        WAIT_BRESP : begin
          
          if(bvalid) begin
            ack = 1'b1;
            next_state = IDLE;
          end
        
        end
        
        
        SETUP_READ : begin
          if(arready) begin
            next_state = READ_DATA;
          end
        
        
        end
        
        READ_DATA : begin
          if(rready) begin
            if(rvalid) begin
              if(rlast) begin
                ack = 1'b1;
                next_state = IDLE;
              end
            end
          end
             
        
        
        end
      default : begin
        next_state = IDLE;
      end
    endcase
  
    
    end
    
    
    
    
endmodule