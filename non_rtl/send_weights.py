import serial
import time
import sys
import os

def main():
    if len(sys.argv) < 2:
        print("Usage: python send_weights.py <COM_PORT>")
        print("Example: python send_weights.py COM3")
        sys.exit(1)
        
    com_port = sys.argv[1]
    weights_path = "weights.bin"
    
    if not os.path.exists(weights_path):
        print(f"Error: {weights_path} not found in this folder!")
        sys.exit(1)
        
    print(f"Loading {weights_path}...")
    with open(weights_path, 'rb') as f:
        weight_bytes = f.read()
        
    print(f"Total INT8 Weights Size: {len(weight_bytes)} bytes ({len(weight_bytes)/1024/1024:.2f} MB)")
    
    # 2. Open Serial Port
    print(f"Opening {com_port} at 921600 baud...")
    try:
        ser = serial.Serial(com_port, 921600, timeout=1)
    except Exception as e:
        print(f"Failed to open port: {e}")
        sys.exit(1)
        
    # 3. Send Weights Data
    print("WARNING: This will take approximately 3 minutes at 921600 baud.")
    print("You only need to do this ONCE after turning on the board!")
    print("Sending weights to Zynq DDR at 0x00000000...")
    start_time = time.time()
    
    chunk_size = 4096
    for i in range(0, len(weight_bytes), chunk_size):
        chunk = weight_bytes[i:i+chunk_size]
        ser.write(chunk)
        
        # Simple progress bar
        progress = int(50 * i / len(weight_bytes))
        sys.stdout.write(f"\r[{'='*progress}{' '*(50-progress)}] {i}/{len(weight_bytes)} bytes")
        sys.stdout.flush()
        
    sys.stdout.write(f"\r[{'='*50}] {len(weight_bytes)}/{len(weight_bytes)} bytes\n")
    print(f"Weights Upload complete in {time.time() - start_time:.2f} seconds!")
    ser.close()

if __name__ == "__main__":
    main()
