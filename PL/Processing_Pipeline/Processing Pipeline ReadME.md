RTL Processing Pipeline
Overview
This section of the repository contains the custom RTL (Register Transfer Level) design for the Tiny YOLOv2 hardware accelerator. Implemented on the Programmable Logic (PL) of the Xilinx Zynq ZC702, this pipeline is responsible for offloading the most compute-intensive parts of the neural network—specifically the Convolutional and Activation layers—from the ARM processor.

Pipeline Architecture
Data flows through the hardware pipeline in a continuous stream, managed by AXI Burst. The general data path is:

AXI Burst (from DDR3) ➔ Skewing Logic ➔ Systolic Array ➔ Deskewing Logic ➔ Activation & Quantization ➔ AXI Burst (to DDR3)

1. Data Skewing & Deskewing
To feed the systolic array correctly, data cannot be sent all at once.

Skewing Module: Staggers the input image data and weights by delaying specific data streams using shift registers. This ensures the correct values meet at the right processing nodes at the exact right clock cycle.
Deskewing Module: Realigns the staggered output data from the systolic array back into a synchronized, parallel format before it moves to the next layer.
2. Systolic Array
The core of the compute pipeline. Convolutions require massive amounts of Multiply-Accumulate (MAC) operations.

The systolic array is a grid of Processing Elements (PEs).
As data flows through the grid rhythmically, partial sums are calculated and passed to the next node.
This module utilizes the ZC702's DSP48E1 slices to perform matrix multiplication operations.
3. Activation Function (Leaky ReLU)
Immediately following the matrix multiplication, the hardware applies the Leaky ReLU activation function. It multiplies negative values by 0.1 while keeping positive values the same.

4. 8-Bit Quantization Bridge
While the internal MAC operations accumulate into higher-precision values to maintain accuracy, transferring 32-bit or 16-bit data back and forth to memory creates a massive bottleneck.

The quantizer converts all pixel values down to 8 bits.

Memory Management
BRAM : The memory on PL, known as BRAM is used to house the input, output, and weight buffers as well as the accumulator module.

DDR3 : Each layer's output is send tile by tile back to the DDR3, after which it is called back for the next layer.