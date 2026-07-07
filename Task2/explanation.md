# Explanation of Task 2 


## 1. The Task

Upgrade task 1. Create a verilog module that uses convolutions to sequentially perform Erosion, Dilation and a third operation of my choice (i chose inversion because it is easy lol).

Erosion paired with dilation resuts in a compound operation known as Opening, which essentially gets the same image while removing any color inconsistences/dead pixels/background noise. 


## 2. The Code 

I'm gonna gloss over the python encode and decode codes, and the testbench as they're basically the same as they were in task 1 with trivial changes.


The RTL module :

```
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
```

This code can be divided into 4 sections:

### 1.Grayscaling 

Morphological logicals, although possible on RGB images, are generally used for binary or grayscaled images. This makes it a necessity for us to ensure that the hex data we deal with is in grayscale and not hex.

The snoopy image which we use, although black and white, is still encoded in RGB.

### 2. Erosion
 Erosion is a process which scans the image with a 3x3 kernel, and replaces the middle pixel with the smallest valued pixel in the 3x3 grid at every step.

 What this does : this shrinks the bright foreground (assuming the foreground is lighter than the background), and also gets rid of any noise in the image.

### 3. Dilation
Dilation is basically the reverse of Erosion. The middle pixel in the kernel at every single stage is replaced by the highest valued pixel in the matrix.

This enlarges the foreground but also magnifies noises and errors in the image.

### 4. Inversion
The easiest part of the image. The top left corner pixel is replaced by the bottom right pixel and so on for the entire image which rotates the image by 180 degrees. 

## 3. Opening

When following up Erosion with Dilation, we get an output image that roughly looks the exact same, with all the minor inconsistencies removed. 

If you look at the output snoopy image, certain inconsistences in colouring like the white pixels at Snoopy's ear are filled up.

In real life applications, this is usually used to clear up noise from images.


## 4. Closing notes

If you noticed that the code is pretty inefficiet, you'd be right. it took me like 20 minutes to compile it on iVerilog, mostly because of the large number of for loops. using so many massive for loops is pretty unrealistic for synthesis (which is why i'm not synthesising this lmao). 

I'll be working on finding a realistic synthesisable method to perform this task, and update this folder as soon as i do.

Also, the reason why the output image has a black background instead of no background like the input is because it is a screenshot of the actual output that vscode gave me. It wouldn't let me save the output for some reason but a screenshot shall suffice.

