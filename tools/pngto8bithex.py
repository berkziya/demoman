#!/usr/bin/env python3
from PIL import Image
import os
import sys

# The special hex code for fully transparent pixels
TRANSPARENT_HEX_CODE = "E3"  # 11100011 in binary


def rgb_to_rrrgggbb(r, g, b):
    """Convert 8-bit RGB to 3-3-2 RRRGGGBB format."""
    r3 = (r >> 5) & 0x07  # Top 3 bits of Red
    g3 = (g >> 5) & 0x07  # Top 3 bits of Green
    b2 = (b >> 6) & 0x03  # Top 2 bits of Blue
    return (r3 << 5) | (g3 << 2) | b2


def image_to_hex(image_path, output_path):
    try:
        # Open the image and convert to RGBA to access the alpha channel
        img = Image.open(image_path).convert("RGBA")
        width, height = img.size  # Get image dimensions
        pixels = list(img.getdata())  # Get data as (R, G, B, A) tuples

        with open(output_path, "w") as f:

            # Write pixel data
            for r, g, b, a in pixels:
                if a == 0:  # Check if the pixel is fully transparent
                    f.write(TRANSPARENT_HEX_CODE)
                else:
                    # For non-transparent or semi-transparent pixels, use RRRGGGBB
                    hex_val_numeric = rgb_to_rrrgggbb(r, g, b)
                    f.write(f"{hex_val_numeric:02X}")

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
        print("Usage: python pngto8bithex.py <image_file>")
        sys.exit(1)

    input_path = sys.argv[1]

    # Ensure the input file exists before proceeding
    if not os.path.isfile(input_path):
        print(f"Error: Input file '{input_path}' does not exist or is not a file.")
        sys.exit(1)

    # Generate output path based on input path
    output_path = os.path.splitext(input_path)[0] + ".hex"

    image_to_hex(input_path, output_path)
