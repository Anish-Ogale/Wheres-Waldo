
module testbench;
  reg clk;
  
  
  reg [23:0] memory_in [0:255][0:255];
  wire [7:0] memory_out[0:255][0:255];
  integer out;
  integer i;
  integer j;
  
  example e1(.clk(clk),.img_in(memory_in),.img_out(memory_out));
  
  always #5 clk = ~clk;
  initial begin
    clk = 1'b0;
  
    $readmemh("snoopy_rgb.hex",memory_in);
    out = $fopen("hex_out.hex","w");
    
   
	#20;
      
    
    for( i=0;i<256;i=i+1) begin
      for(j=0;j<256;j=j+1)begin
        $fdisplay(out,"%02x",memory_out[i][j]);
    end
    end
    
    $fclose(out);
    $display("simulation complete");
    $finish;
  end
endmodule
