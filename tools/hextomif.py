#!/usr/bin/env python3
import sys


def continuous_hex_to_mif(hex_path, mif_path, word_width=8):
    # Read entire file as one string
    with open(hex_path, "rb") as f:
        hex_bytes = f.read()
        hex_string = hex_bytes.hex()

    # Each word is 2 hex characters for 8-bit
    word_length = word_width // 4  # 8 bits = 2 hex chars
    values = [
        hex_string[i : i + word_length] for i in range(0, len(hex_string), word_length)
    ]

    depth = len(values)

    with open(mif_path, "w") as f:
        f.write(f"WIDTH={word_width};\n")
        f.write(f"DEPTH={depth};\n\n")
        f.write("ADDRESS_RADIX=UNS;\n")
        f.write("DATA_RADIX=HEX;\n\n")
        f.write("CONTENT BEGIN\n")
        for i, val in enumerate(values):
            f.write(f"    {i} : {val.upper()};\n")
        f.write("END;\n")


# main function take only file input name infer output name
if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python hextomif.py <input_hex_file>")
    else:
        input_hex = sys.argv[1]
        continuous_hex_to_mif(input_hex, input_hex.replace(".hex", ".mif"))
        print(f"Converted {input_hex} to {input_hex.replace('.hex', '.mif')}")
