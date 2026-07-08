module testbench;
  
  wire [7:0] memory_out[0:255];
  
  reg [23:0] l1[0:255];
  reg [23:0] l2[0:255];
  reg [23:0] l3[0:255];
  reg clk;
  
  
  Top t1(
    .clk(clk), 
    .l1(l1), 
    .l2(l2), 
    .l3(l3), 
    .gradient_out(memory_out)
  );
  
 reg [23:0] memory_in [0:255][0:255];
  integer out;
  integer i,j,k;
  
  
  
  always #5 clk = ~clk;
  
  initial begin
    clk = 1'b0;
    $readmemh("snoopy_rgb.hex",memory_in);
    out = $fopen("hex_out.hex","w");
    
    for(i=0;i<254;i=i+1) begin
      for(j=0;j<256;j=j+1)begin
        l1[j]= memory_in[i][j]; 
        l2[j]= memory_in[i+1][j];
        l3[j]= memory_in[i+2][j];
      end
      
      @(posedge clk);
      @(posedge clk);
      #1 ;
      for(k=0;k<256;k=k+1) begin
        $fdisplay(out,"%02x",memory_out[k]);
      end
    end
    
    $fclose(out);
    $display("simulation complete");
    $finish;
  end
endmodule
