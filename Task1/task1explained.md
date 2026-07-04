# Explaination of Task 1

## 1. The Task 
 
 Figure out how to get image data as input in a verilog hardware module, and perform any basic operations if possible.

 ## 2. The Solution

### a. The decoder

```
from PIL import Image
filename = "cat.png"
img = Image.open(filename).convert("L")  # Convert to grayscale

width = 256
height = 256

img = img.resize((width, height))
pixels = img.load()

with open("cat_gray.hex", "w") as f:
    for y in range(height):
        for x in range(width):
          pixel_value = f"{pixels[x, y]:02x}\n"
            f.write(pixel_value)
```

This code takes the original image, converts it to grayscale(for convenience), and turns it into a hex file of 2 digit hex numbers.

### b. The testbench 

```
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
```

The testbench first stores the image's hex data in an 8 bit, 256*256 word long memory array. it then inputs that into the hardware module one pixel at a time, and writes the output into another hex file.


### c. The hardware module

```
module example (
  input [7:0] pixel_in,
  output [7:0] pixel_out
		
);
  assign pixel_out = 8'hff-pixel_in;
endmodule
```
This code is pretty basic. It just takes the pixel input and inverts it as the output. 

### d. The decoder

```
from PIL import Image
filename = "cat.png"
img = Image.open(filename).convert("L")  # Convert to grayscale

width = 256
height = 256

img = img.resize((width, height))
pixels = img.load()

with open("cat_gray.hex", "w") as f:
    for y in range(height):
        for x in range(width):
            pixel_value = f"{pixels[x, y]:02x}\n"
            f.write(pixel_value)
```
This converts the hex file outputted by the testbench into the desired image.


## 3. Things To Note

If we were to synthesise this code on an actual FPGA, the input would be from our actual image source (like the live video camera for our final project), and the output would probably be on a monitor connected via an HDMI cable to the FPGA board. 



        
    

 

