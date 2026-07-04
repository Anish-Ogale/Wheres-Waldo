module testbench;
   reg [7:0] pixels_in;
   wire [7:0] pixels_out;
  
  
  reg [7:0] memory [0:256*256-1];
  integer out;
  integer i;
  
  example e1(.pixel_in(pixels_in),.pixel_out(pixels_out));
  
  initial begin
  	$readmemh("cat_gray.hex",memory);
    out = $fopen("hex_out.hex","w");
    
    for(i=0;i<256*256;i=i+1) begin
      pixels_in=memory[i];
      
      
      #5;
      
      $fdisplay(out,"%02x",pixels_out);
    end
    
    $fclose(out);
    $display("simulation complete");
    $finish;
  end
endmodule
