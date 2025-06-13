from PIL import Image

# input png filenames
input_files = [   
    "opening.png",
    "ball.png",
    "ball30.png",
    "ball60.png",
    "ball90.png",
    "ball120.png",
    "ball150.png",
    "pokemon_1_1.png",
    "pokemon_1_2.png",
    "pokemon_2_1.png",
    "pokemon_2_2.png",
    "pokemon_3_1.png", 
    "pokemon_3_2.png",
    "pokemon_4_1.png",
    "pokemon_4_2.png",
    "pokemon_5_1.png",
    "pokemon_5_2.png",
    "pokemon_6_1.png",
    "pokemon_6_2.png",
    "badge_1.png",
    "badge_2.png",
    "badge_3.png",
    "badge_4.png",
    "badge_5.png",
    "badge_6.png",
    "logo.png"
]

output_bin = "sram.bin"  # output bin filename
output_txt = "sram.txt"  # output txt filename for address lookup table

# output .bin file
with open(output_bin, "wb") as f_bin:
    with open(output_txt, "w") as f_txt:
        f_txt.write("filename\taddress\n")
        f_txt.write("---------------------\n")

        addr = 0
        for file in input_files:
            f_txt.write(f"{file}\t{addr:X}\n")

            with Image.open("png/" + file) as img:
                img = img.convert("RGBA")
                pixels = list(img.getdata())

                for r, g, b, a in pixels:
                    r5 = r >> 3
                    g5 = g >> 3
                    b5 = b >> 3
                    a1 = 1 if a >= 128 else 0
                    rgba5551 = (r5 << 11) | (g5 << 6) | (b5 << 1) | a1
                    rgba5551 = (((rgba5551 >> 8) | (rgba5551 << 8)) & 0xFFFF)

                    f_bin.write(rgba5551.to_bytes(2, byteorder='big'))
                    addr += 1
                
            print(f"successfully compressed {file} to : {output_bin}")