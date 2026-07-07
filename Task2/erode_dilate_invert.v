module example (
  input clk,
  input [23:0] img_in [0:255][0:255],
  output reg [7:0] img_out[0:255][0:255]
		
);
  
  integer i0,j0,i,j,i1,j1,k,k1,i2,j2;
  
  reg [9:0] gray_sum;
  reg [17:0] mul;
  reg [7:0] gray;
  
  
  reg [7:0] grayscale[0:255][0:255];
  reg [7:0] temp_gray [8:0];
  reg [7:0] min;
  reg [7:0] eroded [0:255][0:255];
  reg [7:0] max;
  reg [7:0] temp_dil[8:0];
  reg [7:0] dilated [0:255][0:255];
  
  
  
  
  
  
  always @(*) begin
    for(i=0;i<256;i=i+1) begin
      for(j=0;j<256;j=j+1) begin
        gray_sum = ({2'b0,img_in[i][j][7:0]}+{2'b0,img_in[i][j][15:8]}+{2'b0,img_in[i][j][23:16]});
  		 mul = gray_sum*8'd85;
        grayscale[i][j] = mul>>8;
      end
    end
  end
  
  
  always @(posedge clk) begin 
    for(j1=0;j1<254;j1=j1+1) begin //erosion
      for(i1=0;i1<254;i1=i1+1) begin
        temp_gray[0] = grayscale[i1][j1];
        temp_gray[1] = grayscale[i1+1][j1];
        temp_gray[2] = grayscale[i1+2][j1];
        temp_gray[3] = grayscale[i1][j1+1];
        temp_gray[4] = grayscale[i1+1][j1+1];
        temp_gray[5] = grayscale[i1+2][j1+1];
        temp_gray[6] = grayscale[i1][j1+2];
        temp_gray[7] = grayscale[i1+1][j1+2];
        temp_gray[8] = grayscale[i1+2][j1+2];
         
        min = 8'd255;
        for( k=0;k<9;k=k+1) begin
          if(temp_gray[k]<=min) begin
            min = temp_gray[k];
          end
        end
        eroded[i1+1][j1+1] = min;
      end
    end
    
    
    for(j0=1;j0<253;j0=j0+1) begin //dilation
      for(i0=1;i0<253;i0=i0+1)begin
        temp_dil[0]= eroded[i0][j0];
        temp_dil[1]=eroded[i0+1][j0];
        temp_dil[2]= eroded[i0+2][j0];
        temp_dil[3]= eroded[i0][j0+1];
        temp_dil[4]= eroded[i0+1][j0+1];
        temp_dil[5]= eroded[i0+2][j0+1];
        temp_dil[6]= eroded[i0][j0+2];
        temp_dil[7]= eroded[i0+1][j0+2];
        temp_dil[8]= eroded[i0+2][j0+2];
        
        max = 8'd0;
        
        for(k1=0;k1<9;k1=k1+1) begin
          if(temp_dil[k1]>=max) begin
            max=temp_dil[k1];
          end
        end
        dilated[i0+1][j0+1]=max;
      end
    end
    
    
    for(j2=2;j2<254;j2=j2+1) begin //inversion
      for(i2=2;i2<254;i2=i2+1) begin
        img_out[i2][j2] = dilated[255-i2][255-j2];
      end
    end
  end
  
 
   
endmodule
        