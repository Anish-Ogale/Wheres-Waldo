from PIL import Image

width, height = 411, 486

with open("output_pixels.mem") as f:
    values = [int(line.strip(), 16) for line in f if line.strip()]

# unpack 24-bit hex back into (R,G,B) tuples
pixels = [((v >> 16) & 0xFF, (v >> 8) & 0xFF, v & 0xFF) for v in values]

img = Image.new("RGB", (width, height))
img.putdata(pixels)
img.save("cat_inverted.png")