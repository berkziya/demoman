#!/usr/bin/env python3
from PIL import Image
import os
import sys

# The special binary code for fully transparent pixels
TRANSPARENT_BINARY_CODE = 0b0
FILLED_BINARY_CODE = 0b1


def png_to_1bit_binary(image_path, output_path):
    try:
        # Open the image and convert to RGBA to access the alpha channel
        img = Image.open(image_path).convert("RGBA")
        width, height = img.size  # Get image dimensions
        pixels = list(img.getdata())  # Get data as (R, G, B, A) tuples
        buffer = []

        for r, g, b, a in pixels:
            if a == 0:  # Check if the pixel is fully transparent
                buffer.append(TRANSPARENT_BINARY_CODE)
            else:
                # For non-transparent pixels, use filled binary code
                buffer.append(FILLED_BINARY_CODE)

        byte_array = bytearray()
        for i in range(0, len(buffer), 8):
            byte = 0
            for j in range(8):
                if i + j < len(buffer):
                    byte |= (buffer[i + j] << (7 - j))  # Set the bit in the byte
            byte_array.append(byte)
        # If the last byte is not full, it will be padded with zeros
        if len(buffer) % 8 != 0:
            # Calculate how many bits are left
            remaining_bits = len(buffer) % 8
            # Create a mask to clear the unused bits in the last byte
            mask = (1 << (8 - remaining_bits)) - 1
            byte_array[-1] &= mask

        # Write the byte array to the output file
        with open(output_path, "wb") as f:
            f.write(byte_array)
        # Print success message
        if len(byte_array) == 0:
            print(f"Warning: No data written to '{output_path}'. The image may be empty.")
        else:
            print(f"Output written to '{output_path}' with {len(byte_array)} bytes.")

        print(
            f"Successfully converted '{image_path}' ({width}x{height}) to '{output_path}'"
        )

    except FileNotFoundError:
        print(f"Error: Input image '{image_path}' not found.")
        sys.exit(1)
    except Exception as e:
        print(f"An error occurred: {e}")
        sys.exit(1)

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python pngto1bitbinary.py <image_file>")
        sys.exit(1)

    input_path = sys.argv[1]

    # Ensure the input file exists before proceeding
    if not os.path.isfile(input_path):
        print(f"Error: Input file '{input_path}' does not exist or is not a file.")
        sys.exit(1)

    # Generate output path based on input path
    output_path = os.path.splitext(input_path)[0] + ".hex"

    png_to_1bit_binary(input_path, output_path)
    sys.exit(0)