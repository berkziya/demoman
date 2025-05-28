#!/usr/bin/env python3
from PIL import Image
import sys

# --- Configuration ---
IMAGE_WIDTH = 120
IMAGE_HEIGHT = 240
# --- End Configuration ---


def rrrgggbb_to_rgb(pixel_val_8bit):
    """
    Converts an 8-bit RRRGGGBB value back to an (R, G, B) tuple.
    RRR: Top 3 bits of Red
    GGG: Top 3 bits of Green
    BB:  Top 2 bits of Blue
    """
    r3 = (pixel_val_8bit >> 5) & 0x07  # Extract RRR (bits 7-5)
    g3 = (pixel_val_8bit >> 2) & 0x07  # Extract GGG (bits 4-2)
    b2 = pixel_val_8bit & 0x03  # Extract BB  (bits 1-0)

    # Scale back to 8-bit per channel for display
    # This replicates the most significant bits to fill 8 bits
    r8 = (r3 << 5) | (r3 << 2) | (r3 >> 1)
    g8 = (g3 << 5) | (g3 << 2) | (g3 >> 1)
    b8 = (b2 << 6) | (b2 << 4) | (b2 << 2) | b2

    return (r8, g8, b8)


def view_hex_image(hex_file_path, width, height):
    try:
        with open(hex_file_path, "r") as f:
            hex_data_stream = f.read().replace("\n", "").replace(" ", "")
    except FileNotFoundError:
        print(f"Error: Hex file '{hex_file_path}' not found.")
        return
    except Exception as e:
        print(f"Error reading hex file: {e}")
        return

    rgb_pixels = []
    expected_hex_chars = width * height * 2

    if len(hex_data_stream) < expected_hex_chars:
        print(
            f"Warning: Hex file contains less data ({len(hex_data_stream)} chars) than expected for a {width}x{height} image ({expected_hex_chars} chars). Image might be incomplete."
        )
    elif len(hex_data_stream) > expected_hex_chars:
        print(
            f"Warning: Hex file contains more data ({len(hex_data_stream)} chars) than expected for a {width}x{height} image ({expected_hex_chars} chars). Extra data will be ignored."
        )

    for i in range(0, min(len(hex_data_stream), expected_hex_chars), 2):
        hex_pair = hex_data_stream[i : i + 2]
        if len(hex_pair) < 2:
            print(f"Warning: Incomplete hex pair at end of file: '{hex_pair}'")
            break
        try:
            pixel_val_8bit = int(hex_pair, 16)
            rgb_tuple = rrrgggbb_to_rgb(pixel_val_8bit)
            rgb_pixels.append(rgb_tuple)
        except ValueError:
            print(f"Warning: Invalid hex value '{hex_pair}' found. Skipping.")
            # Add a placeholder pixel or skip to maintain image structure if desired
            # For simplicity, we just skip, which might misalign subsequent pixels
            # Or, to maintain alignment for valid data:
            # rgb_pixels.append((0,0,0)) # Add a black pixel for errors

    if not rgb_pixels:
        print("No valid pixel data found to display.")
        return

    # If there wasn't enough data, fill the rest with black or a noticeable color
    if len(rgb_pixels) < width * height:
        print(
            f"Padding image as not enough pixel data was found/valid ({len(rgb_pixels)} out of {width * height})."
        )
        padding_needed = width * height - len(rgb_pixels)
        rgb_pixels.extend([(255, 0, 255)] * padding_needed)

    try:
        img = Image.new("RGB", (width, height))
        img.putdata(rgb_pixels)
        img.show()
        print(
            f"Displaying image from '{hex_file_path}' with dimensions {width}x{height}."
        )
    except Exception as e:
        print(f"Error creating or displaying image: {e}")


if __name__ == "__main__":
    if len(sys.argv) > 1:
        hex_file = sys.argv[1]
        view_hex_image(hex_file, IMAGE_WIDTH, IMAGE_HEIGHT)
