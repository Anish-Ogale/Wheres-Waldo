import numpy as np
import os
import struct

def parse_darknet_weights(weights_path, output_path):
    print(f"Parsing Darknet weights from: {weights_path}")
    
    # Tiny YOLOv2 Layer specifications (filters, in_channels, kernel_size)
    layers = [
        (16, 3, 3),      # Layer 0
        (32, 16, 3),     # Layer 1
        (64, 32, 3),     # Layer 2
        (128, 64, 3),    # Layer 3
        (256, 128, 3),   # Layer 4
        (512, 256, 3),   # Layer 5
        (1024, 512, 3),  # Layer 6
        (1024, 1024, 3), # Layer 7
        (125, 1024, 1)   # Layer 8 (Linear, No BN)
    ]

    with open(weights_path, 'rb') as f:
        # Read header (major, minor, revision, seen)
        # v2 uses 4 int32s (16 bytes)
        header = np.fromfile(f, dtype=np.int32, count=4)
        print(f"Header: {header}")

        all_quantized_weights = []

        for i, (filters, in_c, k) in enumerate(layers):
            print(f"Processing Layer {i}: {filters} filters, {in_c} channels, {k}x{k} kernel")
            
            # Layer 8 does not have Batch Normalization in Tiny YOLOv2
            has_bn = (i != 8)

            if has_bn:
                biases = np.fromfile(f, dtype=np.float32, count=filters)
                scales = np.fromfile(f, dtype=np.float32, count=filters)
                rolling_mean = np.fromfile(f, dtype=np.float32, count=filters)
                rolling_var = np.fromfile(f, dtype=np.float32, count=filters)
            else:
                biases = np.fromfile(f, dtype=np.float32, count=filters)

            # Read convolutional weights
            weight_count = filters * in_c * k * k
            weights = np.fromfile(f, dtype=np.float32, count=weight_count)
            weights = weights.reshape((filters, in_c, k, k))

            # Fold Batch Normalization into the weights
            if has_bn:
                # W_fold = W * (scale / sqrt(var + eps))
                bn_scale = scales / np.sqrt(rolling_var + 0.000001)
                for f_idx in range(filters):
                    weights[f_idx, :, :, :] *= bn_scale[f_idx]
            
            # Quantize to INT8
            max_val = np.max(np.abs(weights))
            if max_val == 0: max_val = 1.0 # Prevent div by zero
            
            # Scale to [-127, 127]
            scale = 127.0 / max_val
            quantized_weights = np.round(weights * scale)
            quantized_weights = np.clip(quantized_weights, -127, 127).astype(np.int8)

            # Flatten and append to our massive binary array
            all_quantized_weights.append(quantized_weights.flatten())

    # Concatenate all layers into one massive 1D array
    final_bin = np.concatenate(all_quantized_weights)
    
    # Save to weights.bin
    final_bin.tofile(output_path)
    print(f"\nSUCCESS! Quantized weights saved to: {output_path}")
    print(f"Total INT8 Parameters: {len(final_bin)} bytes ({len(final_bin)/1024/1024:.2f} MB)")

if __name__ == '__main__':
    # Input: The raw float32 darknet file
    input_file = r"C:\Users\HP\Downloads\yolov2-tiny-voc.weights"
    
    # Output: The INT8 binary file for the FPGA
    output_file = r"C:\Users\HP\Wheres-Waldo\non_rtl\weights.bin"
    
    if not os.path.exists(input_file):
        print(f"Error: Could not find {input_file}")
    else:
        parse_darknet_weights(input_file, output_file)
