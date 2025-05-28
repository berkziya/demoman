#!/usr/bin/env python3
from PIL import Image
import os
import sys


def rgb_to_rrrgggbb(r, g, b):
    """Convert 8-bit RGB to 3-3-2 RRRGGGBB format."""
    r3 = (r >> 5) & 0x07
    g3 = (g >> 5) & 0x07
    b2 = (b >> 6) & 0x03
    return (r3 << 5) | (g3 << 2) | b2


def image_to_hex(image_path, output_path):
    img = Image.open(image_path).convert("RGB")
    pixels = list(img.getdata())

    with open(output_path, "w") as f:
        for r, g, b in pixels:
            hex_val = rgb_to_rrrgggbb(r, g, b)
            f.write(f"{hex_val:02X}")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        exit("Usage: python pngto8bithex.py <image_file>")
    input_path = sys.argv[1]
    output_path = os.path.splitext(input_path)[0] + ".hex"
    image_to_hex(input_path, output_path)
