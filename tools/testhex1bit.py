#!/usr/bin/env python3
from PIL import Image
import sys

# --- Configuration ---
IMAGE_WIDTH = 64
IMAGE_HEIGHT = 78
# --- End Configuration ---

## hex file format:
# 0b1 for black pixel
# 0b0 for white pixel
def hex_to_rgb(pixel_val):
    """
    Converts a 1-bit pixel value to an (R, G, B) tuple.
    0b1 (black) -> (0, 0, 0)
    0b0 (white) -> (255, 255, 255)
    """
    return (0, 0, 0) if pixel_val else (255, 255, 255)

def view_hex_image(hex_file_path, width, height):
    try:
        with open(hex_file_path, "rb") as f:
            hex_bytes = f.read()
            # continuous_hex_string is a single string like "ff00aa..."
            continuous_hex_string = hex_bytes.hex()
    except FileNotFoundError:
        print(f"Error: HEX file '{hex_file_path}' not found.")
        return
    except Exception as e:
        print(f"Error reading HEX file: {e}")
        return

    if not continuous_hex_string:
        print("Error: HEX file is empty or resulted in no hex data.")
        return

    rgb_pixels = []
    total_pixels_expected = width * height
    pixels_processed = 0

    # Iterate over the continuous_hex_string, two characters (one byte) at a time
    for i in range(0, len(continuous_hex_string), 2):
        if pixels_processed >= total_pixels_expected:
            break  # Already have enough pixels for the image

        hex_byte_str = continuous_hex_string[i : i + 2]

        if len(hex_byte_str) < 2:
            print(f"Warning: Incomplete hex byte ('{hex_byte_str}') at end of stream. Ignoring.")
            continue

        try:
            byte_val = int(hex_byte_str, 16)
        except ValueError:
            print(f"Warning: Invalid hex byte string '{hex_byte_str}' encountered. Skipping.")
            continue

        # Extract 8 bits (pixels) from this byte. Assuming MSB is the first pixel.
        for bit_pos in range(7, -1, -1):  # Iterate from bit 7 down to 0
            if pixels_processed >= total_pixels_expected:
                break  # Image is full

            pixel_val = (byte_val >> bit_pos) & 1  # Get the bit (0 or 1)
            rgb_pixels.append(hex_to_rgb(pixel_val))
            pixels_processed += 1

    if pixels_processed < total_pixels_expected:
        print(
            f"Warning: HEX data provided {pixels_processed} pixels, "
            f"but {total_pixels_expected} were expected for a {width}x{height} image. "
            "Image will be padded with white pixels."
        )
        # Pad with white pixels if not enough data
        while len(rgb_pixels) < total_pixels_expected:
            rgb_pixels.append(hex_to_rgb(0))  # 0 for white pixel

    # If more pixels were processed than needed, rgb_pixels will be sliced before creating the image.
    # We can add a warning if the input file contained significantly more data.
    hex_chars_needed_for_image = ((total_pixels_expected + 7) // 8) * 2
    if len(continuous_hex_string) > hex_chars_needed_for_image and pixels_processed >= total_pixels_expected:
        print(
            f"Warning: HEX file contains more data than required for a {width}x{height} image. "
            "Extra data has been ignored."
        )
    
    if not rgb_pixels:
        print("Error: No pixels were decoded from the HEX file.")
        return

    # Ensure we only use the exact number of pixels for the image
    final_pixel_data = rgb_pixels[:total_pixels_expected]

    img = Image.new("RGB", (width, height))
    img.putdata(final_pixel_data)
    img.show()

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python testhex1bit.py <path_to_hex_file>")
        sys.exit(1)
    hex_file_path = sys.argv[1]
    view_hex_image(hex_file_path, IMAGE_WIDTH, IMAGE_HEIGHT)
