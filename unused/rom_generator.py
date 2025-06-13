import numpy as np
from PIL import Image

# i/o files
input_files = [             # input png filenames
    "ball.png",
    "ball30.png",
    "ball60.png",
]
output_sizes = [            # output image pixels
    (200, 200),
    (200, 200),
    (200, 200),
]
output_mif = "rom.mif"  # output mif filename
output_txt = "rom.txt"  # output txt filename for address lookup table

# compute output size in words
data_size = 32  # 32 bits per word
num_data = sum(w * h for (w, h) in output_sizes)  # 2 words per pixel for rgba format

# output .mif file
with open(output_mif, "w") as f:
    with open(output_txt, "w") as f_txt:
        f.write(f"WIDTH={data_size};\n")
        f.write(f"DEPTH={num_data};\n")
        f.write("ADDRESS_RADIX=HEX;\n")
        f.write("DATA_RADIX=HEX;\n")
        f.write("CONTENT BEGIN\n")

        f_txt.write("filename\taddress\n")
        f_txt.write("---------------------\n")

        addr = 0
        for i in range(len(input_files)):
            f_txt.write(f"{input_files[i]}\t{addr:X}\n")
            img = Image.open("png/" + input_files[i]).convert("RGBA").resize((output_sizes[i][0], output_sizes[i][1]))
            img_values = np.array(img.getdata())  # shape == (output_sizes[i][0] * output_sizes[i][1] , 4)
                                                # [[r, g, b, a] [r, g, b, a] ...]
            for r, g, b, a in img_values: # concatenate into one 32-bit word
                f.write(f"    {addr:X} : {r:02X}{g:02X}{b:02X}{a:02X};\n")  # :X is in hex format
                addr += 1

        f.write("END;\n")
