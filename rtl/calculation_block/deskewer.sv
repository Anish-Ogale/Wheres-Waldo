`timescale 1ns / 1ps
module deskewer #(

        parameter size = 8

)(
        input clk,
        
        input signed [31:0] pixel_in [0:size-1],
        
        output signed [31:0] pixel_out [0:size-1] 
    );
        
        
        reg signed [31:0] r6;
        reg signed [31:0] r5 [0:1];
        reg signed [31:0] r4 [0:2];
        reg signed [31:0] r3 [0:3];
        reg signed [31:0] r2 [0:4];
        reg signed [31:0] r1 [0:5];
        reg signed [31:0] r0 [0:6];
        
        
        
        
        always @(posedge clk) begin
            
                r6 <= pixel_in[6];
//-------------------------------------------------------------------------------------------
                
                for(int i=0;i<2;i++) begin
                
                    if(i==0) begin
                        r5[i] <= pixel_in[5];
                    end else begin 
                        r5[i] <= r5[i-1] ;
                    end 
                end 
//-------------------------------------------------------------------------------------------
                
                for(int i=0;i<3;i++) begin
                
                    if(i==0) begin
                        r4[i] <= pixel_in[4];
                    end else begin 
                        r4[i] <= r4[i-1] ;
                    end 
                end 
//-------------------------------------------------------------------------------------------
                
                for(int i=0;i<4;i++) begin
                
                    if(i==0) begin
                        r3[i] <= pixel_in[3];
                    end else begin 
                        r3[i] <= r3[i-1] ;
                    end 
                end 
//-------------------------------------------------------------------------------------------
                
                for(int i=0;i<5;i++) begin
                
                    if(i==0) begin
                        r2[i] <= pixel_in[2];
                    end else begin 
                        r2[i] <= r2[i-1] ;
                    end 
                end 
//-------------------------------------------------------------------------------------------
                
                for(int i=0;i<6;i++) begin
                
                    if(i==0) begin
                        r1[i] <= pixel_in[1];
                    end else begin 
                        r1[i] <= r1[i-1] ;
                    end 
                end 
//-------------------------------------------------------------------------------------------
                
                for(int i=0;i<7;i++) begin
                
                    if(i==0) begin
                        r0[i] <= pixel_in[0];
                    end else begin 
                        r0[i] <= r0[i-1] ;
                    end 
                end 
                end
            
            
            
            
            assign pixel_out[0] = r0[6];
            assign pixel_out[1] = r1[5];
            assign pixel_out[2] = r2[4];
            assign pixel_out[3] = r3[3];
            assign pixel_out[4] = r4[2];
            assign pixel_out[5] = r5[1];
            assign pixel_out[6] = r6;
            assign pixel_out[7] = pixel_in[7];


            
            
        
                
                
               
        
    
    
endmodule
