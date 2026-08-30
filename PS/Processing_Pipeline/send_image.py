import serial
import time
from PIL import Image
import numpy as np
import sys

def main():
    if len(sys.argv) < 3:
        print("Usage: python send_image.py <COM_PORT> <image_path>")
        print("Example: python send_image.py COM3 test.jpg")
        sys.exit(1)
        
    com_port = sys.argv[1]
    image_path = sys.argv[2]
    
    # 1. Prepare the image
    print(f"Loading image: {image_path}")
    try:
        img = Image.open(image_path).convert('RGB')
        img = img.resize((416, 416))
    except Exception as e:
        print(f"Failed to open/resize image: {e}")
        sys.exit(1)
    
    # YOLO typically expects CHW or HWC. The FPGA expects HWC.
    # CRITICAL: The FPGA hardware calculates DDR addresses using an 8-byte stride per pixel.
    # Therefore, we must pad the 3 RGB channels with 5 empty channels to match the 64-bit AXI bus!
    img_array = np.array(img, dtype=np.uint8) # Shape: (416, 416, 3)
    
    padded_array = np.zeros((416, 416, 8), dtype=np.uint8)
    padded_array[:, :, 0:3] = img_array # Copy RGB into the first 3 channels
    
    img_bytes = padded_array.tobytes()
    expected_size = 416 * 416 * 8
    
    if len(img_bytes) != expected_size:
        print(f"Error: Expected {expected_size} bytes, got {len(img_bytes)}")
        sys.exit(1)
        
    print(f"Image processed and padded for 64-bit AXI. Size: {len(img_bytes)} bytes.")
    
    # 2. Open Serial Port
    print(f"Opening {com_port} at 921600 baud...")
    try:
        ser = serial.Serial(com_port, 921600, timeout=1)
    except Exception as e:
        print(f"Failed to open port: {e}")
        print("Make sure you don't have a serial terminal (like PuTTY or Vitis Serial Console) already using this port!")
        sys.exit(1)
        
    # 3. Send Image Data
    print("Sending image data to Zynq...")
    start_time = time.time()
    
    # Send in chunks to prevent UART buffer overflow on the Zynq
    chunk_size = 4096
    for i in range(0, len(img_bytes), chunk_size):
        chunk = img_bytes[i:i+chunk_size]
        ser.write(chunk)
        
        # Simple progress bar
        progress = int(50 * i / len(img_bytes))
        sys.stdout.write(f"\r[{'='*progress}{' '*(50-progress)}] {i}/{len(img_bytes)} bytes")
        sys.stdout.flush()
        
    sys.stdout.write(f"\r[{'='*50}] {len(img_bytes)}/{len(img_bytes)} bytes\n")
    print(f"Upload complete in {time.time() - start_time:.2f} seconds!")
    
    # 4. Wait for Zynq response
    print("\nListening for FPGA output (Bounding Boxes)...")
    print("-" * 50)
    try:
        while True:
            if ser.in_waiting > 0:
                line = ser.readline().decode('utf-8', errors='ignore').strip()
                if line:
                    print(f"[ZYNQ]: {line}")
            time.sleep(0.01)
    except KeyboardInterrupt:
        print("\nExiting...")
        ser.close()

if __name__ == "__main__":
    main()
