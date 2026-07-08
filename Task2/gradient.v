module inp_erode (
  input clk,
  input [23:0] l1[0:255],
  input [23:0] l2[0:255], 
  input [23:0] l3[0:255],
  output reg [7:0] eroded_out[0:255] 
); 
  
  integer i, i1, k;
  
  reg [9:0] gray_sum;
  reg [17:0] mul;
  
  reg [7:0] grayscale [0:255][0:2];
  reg [7:0] temp_gray [8:0];
  reg [7:0] min;
  
  always @(*) begin
    for(i=0; i<256; i=i+1) begin
      gray_sum = ({2'b0, l1[i][7:0]} + {2'b0, l1[i][15:8]} + {2'b0, l1[i][23:16]});
      mul = gray_sum * 8'd85;
      grayscale[i][0] = mul >> 8;
      
      gray_sum = ({2'b0, l2[i][7:0]} + {2'b0, l2[i][15:8]} + {2'b0, l2[i][23:16]});
      mul = gray_sum * 8'd85;
      grayscale[i][1] = mul >> 8;
      
      gray_sum = ({2'b0, l3[i][7:0]} + {2'b0, l3[i][15:8]} + {2'b0, l3[i][23:16]});
      mul = gray_sum * 8'd85;
      grayscale[i][2] = mul >> 8;
    end
  end
  
  always @(posedge clk) begin 
    for(i1=0; i1<254; i1=i1+1) begin     
      temp_gray[0] = grayscale[i1][0]; 
      temp_gray[1] = grayscale[i1+1][0];
      temp_gray[2] = grayscale[i1+2][0];      
      temp_gray[3] = grayscale[i1][1];
      temp_gray[4] = grayscale[i1+1][1];
      temp_gray[5] = grayscale[i1+2][1];      
      temp_gray[6] = grayscale[i1][2];
      temp_gray[7] = grayscale[i1+1][2];
      temp_gray[8] = grayscale[i1+2][2];       
      
      min = 8'd255;
      for(k=0; k<9; k=k+1) begin
        if(temp_gray[k] <= min) begin
          min = temp_gray[k];
        end
      end      
      eroded_out[i1+1] <= min;       
    end
  end
endmodule


module dilation (
  input clk,
  input [23:0] l1[0:255],
  input [23:0] l2[0:255], 
  input [23:0] l3[0:255],
  output reg [7:0] dilated_out[0:255]
);
  
  integer i, i1, k;
  
  reg [9:0] gray_sum;
  reg [17:0] mul;
  
  reg [7:0] grayscale [0:255][0:2];
  reg [7:0] temp_gray [8:0];
  reg [7:0] max;
  
  always @(*) begin
    for(i=0; i<256; i=i+1) begin
      gray_sum = ({2'b0, l1[i][7:0]} + {2'b0, l1[i][15:8]} + {2'b0, l1[i][23:16]});
      mul = gray_sum * 8'd85;
      grayscale[i][0] = mul >> 8;
      
      gray_sum = ({2'b0, l2[i][7:0]} + {2'b0, l2[i][15:8]} + {2'b0, l2[i][23:16]});
      mul = gray_sum * 8'd85;
      grayscale[i][1] = mul >> 8;
      
      gray_sum = ({2'b0, l3[i][7:0]} + {2'b0, l3[i][15:8]} + {2'b0, l3[i][23:16]});
      mul = gray_sum * 8'd85;
      grayscale[i][2] = mul >> 8;
    end
  end
  
  always @(posedge clk) begin
    for(i1=0; i1<254; i1=i1+1) begin
      temp_gray[0] = grayscale[i1][0]; 
      temp_gray[1] = grayscale[i1+1][0];
      temp_gray[2] = grayscale[i1+2][0];
      temp_gray[3] = grayscale[i1][1];
      temp_gray[4] = grayscale[i1+1][1];
      temp_gray[5] = grayscale[i1+2][1];
      temp_gray[6] = grayscale[i1][2];
      temp_gray[7] = grayscale[i1+1][2];
      temp_gray[8] = grayscale[i1+2][2];
      
      max = 8'd0;
      for(k=0; k<9; k=k+1) begin
        if(temp_gray[k] >= max) begin
          max = temp_gray[k];
        end
      end     
      dilated_out[i1+1] <= max;
    end
  end
endmodule









module gradient (

  input  [7:0] eroded_out[0:255],
  input [7:0] dilated_out[0:255],
  input clk,
  output reg [7:0] gradient_out[0:255]
);
      integer i3;
  
  		
  
  always @(posedge clk) begin
    for(i3=1;i3<255;i3=i3+1) begin
      gradient_out[i3] <= dilated_out[i3] - eroded_out[i3];
  end
  end
endmodule


module Top(
	input clk,
  input [23:0] l1[0:255],
  input [23:0] l2[0:255], 
  input [23:0] l3[0:255],
  output [7:0] gradient_out[0:255]

);
  wire [7:0] eroded_out[0:255]; 
  wire [7:0] dilated_out[0:255];
  
  inp_erode e1(.clk(clk),.l1(l1),.l2(l2),.l3(l3),.eroded_out(eroded_out));
  
  dilation d1 (.clk(clk),.l1(l1),.l2(l2),.l3(l3),.dilated_out(dilated_out));
  
  gradient g1 (.clk(clk),.eroded_out(eroded_out),.dilated_out(dilated_out),.gradient_out(gradient_out));
  
endmodule
    
