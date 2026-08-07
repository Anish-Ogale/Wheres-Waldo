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
            output ack,          // signal that goes high when a transaction is finished
            
//--------------------------------------------------------

            //axi write address channel
            input awready,      //sgnal controlled by slave when it is ready to recieve
            output [7:0] awlen,     //
            output awvalid,             //high when awlen and awaddr are valid
            output [31:0] awaddr,       // address to be written at
            
//-------------------------------------------------------
            //write data channel
            
            input wready,       //slave asserts high when it is ready to accept data
            output [31:0] wdata,        //data to be written to the ddr3
            output [3:0] wstrb,         //
            output wlast,           // high on the last burst
            output wvalid,       //goes high when wdata is valid
            
            
//--------------------------------------------------------
            //write response channel
            
            
            input [1:0] bresp,      //current status of the write
            input bvalid,       //asserted high by slave when response is valid
            output bready,      //signaled high by master when it is ready to recieve response
            
            
//--------------------------------------------------------
            //read data channel
            
            
            input [31:0] rdata,     //data coming from ddr3
            input rlast,           //signals high when the last burst is sent
            input rvalid,           //slave asserts high when rdata is valid
            output rready,          //master asserts hoigh when it is ready to recieve data
            
//----------------------------------------------------------

            //read address channel
            
            output [31:0] araddr,       //address where ddr3 is read from           
            output [7:0] arlen,         //length of address
            output arvalid,             //goes high when araddr is valid
            input arready          //goes high when ddr3 is ready to accept data address 
             
            
            
                 
            
            
            
            
            
    );
    
    
    
    
    reg next_state;
    reg current_state;
    
    
    
    
    
    always @(posedge clk) begin 
        if(rst) begin
            awvalid = '0;
            arvalid = '0;
            rvalid = '0;
            bvalid = '0;
            wvalid = '0;
            current_state <= IDLE;
        
        
    end
    
    
    
    always @(*) begin
    
    case(current_state)
        IDLE : begin
            if(req) begin
                if(we) begin
                    next_state <= SETUP_WRITE;
                end else begin
                    next_state <= SETUP_READ;
                end
            end
    
    
    
    
    end
    
    
    
    
endmodule
