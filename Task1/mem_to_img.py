from PIL import Image

width, height = 411, 486

with open("output_pixels.mem") as f:
    values = [int(line.strip(), 16) for line in f if line.strip()]

img = Image.new("L", (width, height))
img.putdata(values)
img.save("cat_grayscale.png")