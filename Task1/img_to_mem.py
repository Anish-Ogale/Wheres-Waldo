from PIL import Image

img = Image.open("Cat_in_the_hat.png").convert("RGB")
pixels = list(img.getdata())

with open("input_pixels.mem", "w") as f:
    for r, g, b in pixels:
        f.write(f"{r:02X}{g:02X}{b:02X}\n")

print("Image size:", img.size)