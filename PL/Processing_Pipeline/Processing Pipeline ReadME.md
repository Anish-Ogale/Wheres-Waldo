# RTL Processing Pipeline

## Overview
This section of the repository contains the custom RTL (Register Transfer Level) design for the Tiny YOLOv2 hardware accelerator. Implemented on the Programmable Logic (PL) of the Xilinx Zynq ZC702, this pipeline is responsible for offloading the most compute-intensive parts of the neural network—specifically the Convolutional and Activation layers—from the ARM processor. 

The design is optimized for high throughput and efficient memory bandwidth utilization, built heavily around a systolic array architecture.

## Pipeline Architecture
Data flows through the hardware pipeline in a continuous stream, managed by AXI4 protocols. The general data path is:

**AXI DMA (from DDR3) ➔ Skewing Logic ➔ Systolic Array ➔ Deskewing Logic ➔ Activation & Quantization ➔ AXI DMA (to DDR3)**

### 1. Data Skewing & Deskewing
To feed the systolic array correctly, data cannot be sent all at once. 
* **Skewing Module:** Staggers the input image data and weights by delaying specific data streams using shift registers. This ensures the correct values meet at the right processing nodes at the exact right clock cycle.
* **Deskewing Module:** Realigns the staggered output data from the systolic array back into a synchronized, parallel format before it moves to the next layer.

### 2. Systolic Array 
The core of the compute pipeline. Convolutions require massive amounts of Multiply-Accumulate (MAC) operations. 
* The systolic array is a grid of Processing Elements (PEs). 
* As data flows through the grid rhythmically, partial sums are calculated and passed to the next node. 
* This module heavily utilizes the ZC702's DSP48E1 slices to maximize parallel computation while minimizing routing delays.

### 3. Activation Function (Leaky ReLU)
Immediately following the matrix multiplication, the hardware applies the Leaky ReLU activation function. Because Leaky ReLU is computationally simple (multiplying negative values by a small constant), it is implemented directly in the FPGA fabric using simple multiplexers and shift operations, avoiding a trip back to the CPU.

### 4. 8-Bit Quantization Bridge
While the internal MAC operations accumulate into higher-precision values to maintain accuracy, transferring 32-bit or 16-bit data back and forth to memory creates a massive bottleneck. 
* This module quantizes the high-precision output feature maps back down to 8-bit integers.
* This dramatically reduces the DDR3 memory bandwidth required and allows the AXI DMA to operate efficiently within the system's limits.

## Memory Management
* **BRAM Utilization:** Block RAM is used to buffer incoming image tiles and cache network weights, preventing the systolic array from stalling while waiting for DDR3 memory fetches.
* **CPU Offloading:** While convolutions and Leaky ReLU are handled here in the RTL, the final Softmax activation layer is explicitly omitted from the hardware pipeline. It is processed by the ARM CPU to save valuable DSP and logic resources on the FPGA fabric.
