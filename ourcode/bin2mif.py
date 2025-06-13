# i/o files
input_files = [
    "audio_battle.bin",
    "audio_opening.bin",
]
output_mif = "audio.mif"  # output mif filename
output_txt = "audio.txt"  # output txt filename for address lookup table

# compute output size in words
data_size = 16  # 16 bits per word
num_data = 0
for file in input_files:
    with open(file, "rb") as f_bin:
        data = f_bin.read()
        num_data += len(data) // 2  # 2 bytes per word

# output .mif file
with open(output_mif, "w") as f_mif:
    with open(output_txt, "w") as f_txt:
        f_mif.write(f"WIDTH={data_size};\n")
        f_mif.write(f"DEPTH={num_data};\n")
        f_mif.write("ADDRESS_RADIX=HEX;\n")
        f_mif.write("DATA_RADIX=HEX;\n")
        f_mif.write("CONTENT BEGIN\n")

        f_txt.write("filename\taddress\n")
        f_txt.write("---------------------\n")

        addr = 0
        for file in input_files:
            f_txt.write(f"{file}\t{addr:X}\n")
            with open(file, "rb") as f_bin:
                data = f_bin.read()
                for i in range(1, len(data), 2):
                    word = (data[i] << 8) | data[i-1]
                    f_mif.write(f"    {addr:X} : {word:04X};\n")
                    addr += 1

        f_mif.write("END;\n")