from PIL import Image

def decode_hex_to_image(hex_path, image_path, size=256):
    img = Image.new("L", (size, size))   # "L" = grayscale image

    with open(hex_path, "r") as f:
        lines = [line.strip() for line in f if line.strip()]

    idx = 0
    for y in range(size):
        for x in range(size):
            gray = int(lines[idx], 16)
            img.putpixel((x, y), gray)
            idx += 1

    img.save(image_path)
    print(f"Decoded image saved to {image_path}")

decode_hex_to_image("output_image.hex", "snoopy_morph.png", size=256)
