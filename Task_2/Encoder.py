from PIL import Image

def encode_image_to_hex(image_path, hex_path, size=256):
    img = Image.open(image_path).convert("L")
    img = img.resize((size, size))

    with open(hex_path, "w") as f:
        for y in range(size):
            for x in range(size):
                gray = img.getpixel((x, y))
                f.write(f"{gray:02X}\n")

    print(f"Encoded {size}x{size} grayscale image to {hex_path}")

encode_image_to_hex("Snoopy.png", "input_image.hex", size=256)