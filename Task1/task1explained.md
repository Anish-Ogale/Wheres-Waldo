# Explaination of Task 1

## 1. The Task 
 
 Figure out how to get image data as input in a verilog hardware module, and perform any basic operations if possible.

 ## 2. The Solution

### a. The decoder

```
from PIL import Image
filename = "waldo?.png"
img = Image.open(filename)

width = 256
height = 256

img = img.resize((width, height))
img = img.convert("RGB")
pixels = img.load()


with open("waldo_rgb.hex", "w") as f:
    for y in range(height):
        for x in range(width):
            r, g, b = pixels[x, y]
            
            pixel_value = f"{r:02x}{g:02x}{b:02x}\n"
            f.write(pixel_value)
```

This code takes the original image, converts each pixel into a 24 bit hex number and stores that data in a .hex file.

### b. The testbench 

```
module testbench;
  reg [23:0] pixels_in;
  wire [7:0] pixels_out;
  
  
  reg [23:0] memory [0:256*256-1];
  integer out;
  integer i;
  
  example e1(.pixel_in(pixels_in),.pixel_out(pixels_out));
  
  initial begin
    $readmemh("waldo_rgb.hex",memory);
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
```

The testbench first stores the image's hex data in a 24 bit, 256*256 word long memory array. it then inputs that into the hardware module one pixel at a time, and writes the output into another hex file.


### c. The hardware module

```
module example (
  input [23:0] pixel_in,
  output [7:0] pixel_out
		
);
  wire [9:0] gray_sum;
  wire [17:0] mul;
  wire [7:0] gray;
  assign gray_sum = ({2'b0,pixel_in[7:0]}+{2'b0,pixel_in[15:8]}+{2'b0,pixel_in[23:16]});
   assign mul = gray_sum*8'd85;
  assign gray = mul >> 8;
  assign pixel_out = 8'hff - gray;
  
endmodule
```
The hardware module does the task of :

  #### 1. Grayscaling the image : 
  
  It does this by first taking the sum of all 3 colour values, and then dividing that by 3. For the division process, we use approximation by right shifting the bits such that the sum is actually being multiplied by (85/256) which is approximately 0.332 . Although it doesn't affect simulation, this method is much faster when synthesizing on an FPGA board. 

  #### 2. Inverting colours :

  This part is pretty straightforward.the final grayscaled bit is subtracted from FF (in hex).


### d. The decoder

```
from PIL import Image
filename = "waldo?.png"
img = Image.open(filename)

width = 256
height = 256

img = img.resize((width, height))
img = img.convert("RGB")
pixels = img.load()


with open("waldo_rgb.hex", "w") as f:
    for y in range(height):
        for x in range(width):
            r, g, b = pixels[x, y]
            
            pixel_value = f"{r:02x}{g:02x}{b:02x}\n"
            f.write(pixel_value)
```
This converts the hex file outputted by the testbench into the desired image.


## 3. Things To Note

If we were to synthesise this code on an actual FPGA, the input would be from our actual image source (like the live video camera for our final project), and the output would probably be on a monitor connected via an HDMI cable to the FPGA board. 



        
    

 

