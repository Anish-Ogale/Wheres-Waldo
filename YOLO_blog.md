# YOLO 


## 1.What is YOLO? 

YOLO is a modern object detection model whose core concept is to treat object detection as a regression problem, instead of a classification problem. It currently the most efficient and widely used model, surpassing older classification models like R-CNN.

YOLO (You Only Look Once) scans the image once, and uses multiple convolutional layers to detect objects. This is opposed to DPM (Deformable Parts Models) and R-CNN, which scan the original image several times with a classifier to detect objects.

Since object detection is treated as a regression problem, complex pipelines can be avoided, making YOLO extremely fast.This results in a very fast model. The base YOLO v1 can run at about 45 frames per second. Modern YOLO models like the YOLO26-N can run at upto 588 frames per second.

## 2.Working of YOLO

### a) The Core Concept

The core idea of YOLO is "the grid containing the center of an object is responsible for predicting everything about that object". The input image is divided in SxS boxes as a grid. Each grid cell outputs the following predictions :

__1. x and y__ - These are the co-ordinates of the centre of the box relative to the grid cell.

__2. w and h__ - These are the height and width of the bounding box relative to the entire image.

__3.Class probabilities__ - This is the level of certainty by which the model believes that the object's centre is located in that cell. Eg. if we train a model to detect a car and a bike. C(car) could be 95% and C(bike) could be 5%.

__4. Confidence Score__ - Each grid cell outputs the probability of it being the box where the center of the object is located.

![yolo  output vector](https://imerit.ai/wp-content/uploads/2023/04/Embedded-7_Detecting-Objects-in-Images-Using-YOLO-TT.png)



### b) YOLOv1 Architecture

Since YOLOv1 is a form of CNN (Convolutional Neural Network), it consists of 24 convolutional layers, followed by 2 fully connected layers. It takes a 448 x 448 x 3 dimension image as input, and operates on it using convolutions.

![YOLO network image](https://substackcdn.com/image/fetch/$s_!GDfp!,f_auto,q_auto:good,fl_progressive:steep/https%3A%2F%2Fsubstack-post-media.s3.amazonaws.com%2Fpublic%2Fimages%2Fe30217b6-c4ff-4058-ac96-006a35e1404e_700x298.png)

An image of the neural structure of a YOLO model.


__1)3x3 Convolutional Layers__ - These layers run 3x3 weighted kernels on their input maps with varying channels. They are responsible for extracting data out of the input matrix. After each convolutional layer, the output matrix has a smaller height and width, and the number of channels increases.

__2) 1x1 Convolutional Layers__ - Unlike 3x3 Layers, these do not extract any information and do not reduce the height or width of the image. Instead, they're used to control the number of channels of the output. For example, if an input image having 512 channels is operated on by 1x1x512 filter, it compresses those channels into a single layer of data. Using 1024 of these layers together will lead to an output having 1024 channels. This allows us to comfortably increase or decrease the number of channels we deal with, to control complexity.

__3) Max Pooling Layers__ - These are 2x2 untrainable kernel layers having a stride of 2. This stride ensures that at every stage of the scan, the kernel looks at 4 unique pixels, and picks the largest of the 4. This process ensures that the most important parts of an input matrix are conserved, while also reducing its size by 75%.

__4) Fully Connected Layers__ - These are the final 3 layers of the CNN. Instead of being convolutional layers, they are completely different in the sense that every single neuron is connected matematically to every single input. These layers are responsible for taking the abstract data from convolutions and converting it into the final 7x7x30 tensor which describes all the output values of all grid cells.


### c) Sounds perfect, Right?

no.


While YOLOv1 was revolutionary for its time, it had several drawbacks that were later improved upon:

__1) Quantity constraints__ - YOLOv1 was designed such that each grid cell could only detect one class and one object at a time. This meant that even if a cell had 100 objects (like a flock of birds), it could practically only detect 1.


__2) No box guidelines__ - YOLOv1 used 2 fully connected layers at the end to predict all the data of the output vector from scratch. Since there were no prior guidelines as to how the bounding boxes would look, it would often result in weird/inaccurately shaped boxes.


__3) Aspect ratio constraints__ - since the fully connected layers had a fixed number of fully connected neurons, only a certain image size i.e. 448x448x3 was allowed as input. If we wished to change the image size, we would have to completely remake the fully connected layers.

__4) High complexity__ - Although much simpler than DPM and R-CNN models, YOLOv1 still had a fairly high complexity, will 24 total layers of processing needed to get to the final output.

### d) The solution

In 2016, the creators of YOLO came out with YOLOv2, specifically the TinyYOLOv2. This YOLO model greatly improved on its predecessor by:

__1)Being fully convolutional__ - Unlike YOLOv1, this model contains no fully connected layers. This makes it so that the input image size is no longer constrained to one specific dimension.

__2)Adding Anchor Boxes__ - Previously, the model had to figure out the size and shape of the bounding box from complete scratch. However, for YOLOv2, Anchor boxes were introduced. These are pre defined box shapes that the model is fed with before the training. When detecting an object, the model simply resizes the anchor box fit to that object instead of figuring out the shape from scratch.

Eg. A narrow and tall box - Humans, traffic signals, road signs etc.
Eg. A short and wide box - Vehicles, dogs etc.


__3) Less layers__ - TinyYOLOv2 worked with only 9 convolutional layers, no fully connected layers.

![yolo v2 image](https://www.researchgate.net/publication/331423658/figure/fig2/AS:962150793244727@1606406033806/Block-diagram-of-architecture-YOLOv2tiny.png)

Block diagram of the architecture of TinyYOLOv2.

__4) Batch Normalisation__ - YOLOv2 introduced a normalisation layer after every convolutional step in each layer, but before the activation function step. This ensures that the size of the output numbers stays fairly constant as any output is scaled down to a rage (like 0 to 1). 


## 3. How YOLO will work in Where's Waldo

This final section is a short overview of how we plan to run YOLO on an FPGA for our project.


As explained previously, we will be working with the TinyYOLOv2 model for this. Since we need to run the model's convolution engine on an FPGA, our resources are limited. Older models like YOLOv1 are too inefficient, while newer models like YOLOv11 and YOLOv26, although better, are way too complex to run on an FPGA. TinyYOLOv2 finds the perfect sweet spot for this. 

We will be working with a zynq 7000 series SoC, and the working will be split into 2 parts

__1) The PS (Processor System)__ -  This is an ARM Cortex-A9 CPU which will house the operating system, and the actual YOLO program. It contains all the python/c++ code, the class objects and the actual model required to run it.

__2) The PL(Programmable Logic)__ - This is the FPGA portion of the board, which will house the hardware (synthesised from verilog code) required to perform matrix calculations at each step.

