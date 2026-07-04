from PIL import Image
filename = "cat.png"
img = Image.open(filename).convert("L")  # Convert to grayscale

width = 256
height = 256

img = img.resize((width, height))
pixels = img.load()

with open("cat_gray.hex", "w") as f:
    for y in range(height):
        for x in range(width):
            pixel_value = f"{pixels[x, y]:02x}\n"
            f.write(pixel_value)


