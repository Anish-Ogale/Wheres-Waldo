from PIL import Image
filename = "snoopy.png"
img = Image.open(filename)

width = 256
height = 256

img = img.resize((width, height))
img = img.convert("RGB")
pixels = img.load()


with open("snoopy_rgb.hex", "w") as f:
    for y in range(height):
        for x in range(width):
            r, g, b = pixels[x, y]
            
            pixel_value = f"{r:02x}{g:02x}{b:02x}\n"
            f.write(pixel_value)