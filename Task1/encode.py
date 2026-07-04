from PIL import Image


WIDTH = 256
HEIGHT = 256


with open("hex_out.hex", "r") as f:
    img_data = f.read().replace("\n", "").replace(" ", "")


image_bytes = bytes.fromhex(img_data)

try:
   
    image = Image.frombytes('L', (WIDTH, HEIGHT), image_bytes)
    
    image.save("decoded_output.png") 
    image.show()
    print("Success: Image successfully decoded and saved.")
except Exception as e:
    print(f"Error decoding image: {e}")



