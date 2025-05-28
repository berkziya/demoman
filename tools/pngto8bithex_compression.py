#!/usr/bin/env python3
import os
import sys
from PIL import Image
import struct


def rgb_to_rrrgggbb(r, g, b):
    """
    Converts standard RGB (0-255 per channel) to an 8-bit RRRGGGBB value.
    RRR (3 bits for Red), GGG (3 bits for Green), BB (2 bits for Blue).
    """
    # Quantize R and G from 8 bits to 3 bits
    r_3bit = r >> 5  # Equivalent to r // 32
    g_3bit = g >> 5  # Equivalent to g // 32
    # Quantize B from 8 bits to 2 bits
    b_2bit = b >> 6  # Equivalent to b // 64

    # Combine into an 8-bit value: RRRGGGBB
    return (r_3bit << 5) | (g_3bit << 2) | b_2bit


def image_to_rrrgggbb_bytes(image_path):
    """
    Opens an image, converts its pixels to RRRGGGBB format,
    and returns the byte sequence along with image dimensions.
    """
    try:
        img = Image.open(image_path)
        img = img.convert("RGB")  # Ensure image is in RGB format
        width, height = img.size

        rrrgggbb_byte_list = bytearray()  # Use bytearray for efficiency

        for r, g, b in img.getdata():
            rrrgggbb_byte_list.append(rgb_to_rrrgggbb(r, g, b))

        return bytes(rrrgggbb_byte_list), width, height
    except FileNotFoundError:
        print(f"Error: Image file not found at '{image_path}'")
        sys.exit(1)
    except Exception as e:
        print(f"Error processing image '{image_path}': {e}")
        sys.exit(1)


def compress_data_rle(byte_data):
    """
    Compresses a sequence of bytes using Run-Length Encoding (RLE).
    Each run is stored as a pair: [value_byte, count_byte].
    Count can be 1 to 255.
    """
    if not byte_data:
        return b""

    compressed = bytearray()

    count = 1
    prev_byte = byte_data[0]

    for i in range(1, len(byte_data)):
        current_byte = byte_data[i]
        if current_byte == prev_byte and count < 255:
            count += 1
        else:
            compressed.append(prev_byte)
            compressed.append(count)
            prev_byte = current_byte
            count = 1

    # Append the last run
    compressed.append(prev_byte)
    compressed.append(count)

    return bytes(compressed)


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(
            "Usage: python pngto8bithex_compression.py <image_file> [output_compressed_file.hex]"
        )
        sys.exit(1)

    image_file_path = sys.argv[1]

    if len(sys.argv) > 2:
        compressed_file_path = sys.argv[2]
    else:
        base, _ = os.path.splitext(image_file_path)
        # Use the original naming convention for the output file
        compressed_file_path = base + "_compressed.hex"

    print(f"Processing image: {image_file_path}")
    rrrgggbb_data, width, height = image_to_rrrgggbb_bytes(image_file_path)

    if not rrrgggbb_data:
        # Error message handled in image_to_rrrgggbb_bytes
        sys.exit(1)

    print(f"Image dimensions: {width}x{height}")
    print(f"Original RRRGGGBB data size: {len(rrrgggbb_data)} bytes")

    compressed_data = compress_data_rle(rrrgggbb_data)
    print(f"RLE Compressed data size: {len(compressed_data)} bytes")

    try:
        with open(compressed_file_path, "wb") as f:
            # Write width and height as 2-byte unsigned shorts (big-endian)
            f.write(struct.pack(">H", width))
            f.write(struct.pack(">H", height))
            # Write the compressed RLE data
            f.write(compressed_data)
        print(f"Compressed file saved to: {compressed_file_path}")
    except IOError as e:
        print(f"Error writing to file '{compressed_file_path}': {e}")
        sys.exit(1)
