import serial
import time
from PIL import Image

# ==========================================
# CONFIGURATION
# ==========================================
# Update this to match the port found in Phase 2
COM_PORT = '/dev/ttyUSB1'  # Windows example
# COM_PORT = '/dev/ttyUSB1' # Linux example

BAUD_RATE = 19200
WIDTH = 32
HEIGHT = 32
DELAY = (2 * WIDTH) + 4  # The hardware pipeline flush delay

def process_image_on_fpga(input_path, output_path):
    print(f"--- FPGA Image Processor ---")
    
    # 1. Prepare the Input Image
    print(f"Loading '{input_path}'...")
    try:
        img = Image.open(input_path).convert('L') # Convert to grayscale
        img = img.resize((WIDTH, HEIGHT))         # Force exact dimensions
    except Exception as e:
        print(f"Error loading image: {e}")
        return

    # Extract raw pixel bytes
    pixel_data = list(img.getdata())
    
    # Add dummy bytes to push the final valid rows out of the hardware pipeline
    dummy_bytes = [0] * DELAY
    full_tx_payload = bytes(pixel_data + dummy_bytes)

    # 2. UART Communication
    print(f"Opening port {COM_PORT} at {BAUD_RATE} baud...")
    try:
        # timeout=10 ensures the script won't hang forever if the board is disconnected
        with serial.Serial(COM_PORT, BAUD_RATE, timeout=10) as ser:
            # Flush buffers to ensure a clean slate
            ser.reset_input_buffer()
            ser.reset_output_buffer()

            print(f"Sending {len(full_tx_payload)} bytes to the Arty A7...")
            # Send all data to the OS serial buffer
            ser.write(full_tx_payload)

            expected_rx_bytes = WIDTH * HEIGHT
            print(f"Listening for {expected_rx_bytes} bytes from the Arty A7...")
            
            # Block and read the incoming data as the FPGA processes it
            rx_data = ser.read(expected_rx_bytes)

            if len(rx_data) != expected_rx_bytes:
                print(f"TIMEOUT ERROR: Expected {expected_rx_bytes} bytes, but only received {len(rx_data)}.")
                print("Check the baud rate, USB connection, and ensure the FPGA is programmed.")
                return

    except serial.SerialException as e:
        print(f"SERIAL ERROR: Could not open {COM_PORT}. Is the board plugged in? {e}")
        return

    # 3. Reconstruct the Output Image
    print("All bytes received! Reconstructing image...")
    out_img = Image.new('L', (WIDTH, HEIGHT))
    out_img.putdata(list(rx_data))
    
    out_img.save(output_path)
    print(f"SUCCESS! Hardware-accelerated image saved to '{output_path}'")

# ==========================================
# EXECUTION
# ==========================================
if __name__ == '__main__':
    # Place a test image named 'input.png' in the same folder as this script
    process_image_on_fpga("input.png", "fpga_output.png")