import numpy as np
from PIL import Image

# i/o files
input_files = [             # input png filenames
    "ball.png",
]
rotate_angles = [90, 120, 150]

for file in input_files:
    for angle in rotate_angles:
        img = Image.open(file).convert("RGBA").rotate(angle)
        img.save(f"{file.split('.')[0]}{angle}.png")  # Save the rotated image
