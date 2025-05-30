#!/usr/bin/python3
from PIL import Image
import sys

# --- Configuration ---
IMAGE_WIDTH = 150
IMAGE_HEIGHT = 157
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
    r8 = (r3 << 5) | (r3 << 2) | (r3 >> 1)
    g8 = (g3 << 5) | (g3 << 2) | (g3 >> 1)
    b8 = (b2 << 6) | (b2 << 4) | (b2 << 2) | b2

    return (r8, g8, b8)


def view_mif_image(mif_file_path, width, height):
    try:
        with open(mif_file_path, "r") as f:
            mif_data_stream = f.read().splitlines()
    except FileNotFoundError:
        print(f"Error: MIF file '{mif_file_path}' not found.")
        return
    except Exception as e:
        print(f"Error reading MIF file: {e}")
        return
    mif_data_stream = [
        line.strip()
        for line in mif_data_stream
        if line.strip() and not line.startswith("//")
    ]
    if not mif_data_stream:
        print("Error: MIF file is empty or contains no valid data.")
        return
    rgb_pixels = []
    expected_lines = width * height
    if len(mif_data_stream) < expected_lines:
        print(
            f"Warning: MIF file contains less data ({len(mif_data_stream)} lines) than expected for a {width}x{height} image ({expected_lines} lines). Image might be incomplete."
        )
    elif len(mif_data_stream) > expected_lines:
        print(
            f"Warning: MIF file contains more data ({len(mif_data_stream)} lines) than expected for a {width}x{height} image ({expected_lines} lines). Extra data will be ignored."
        )
    for line in mif_data_stream:
        if ":" not in line:
            print(f"Warning: Invalid line format: '{line}'")
            continue
        address, hex_value = line.split(":", 1)
        address = address.strip()
        hex_value = hex_value.strip().rstrip(";")
        if len(hex_value) != 2:
            print(f"Warning: Invalid hex value '{hex_value}' at address {address}")
            continue
        try:
            pixel_val_8bit = int(hex_value, 16)
            rgb_tuple = rrrgggbb_to_rgb(pixel_val_8bit)
            rgb_pixels.append(rgb_tuple)
        except ValueError as e:
            print(f"Error converting hex value '{hex_value}' at address {address}: {e}")
            continue
    if len(rgb_pixels) < expected_lines:
        print(
            f"Warning: MIF file contains less pixel data ({len(rgb_pixels)} pixels) than expected for a {width}x{height} image ({expected_lines} pixels). Image might be incomplete."
        )
    elif len(rgb_pixels) > expected_lines:
        print(
            f"Warning: MIF file contains more pixel data ({len(rgb_pixels)} pixels) than expected for a {width}x{height} image ({expected_lines} pixels). Extra data will be ignored."
        )
    # Create an image from the pixel data
    if not rgb_pixels:
        print("No valid pixel data found to display.")
        return
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
            f"Displaying image from '{mif_file_path}' with dimensions {width}x{height}."
        )
    except Exception as e:
        print(f"Error creating or displaying image: {e}")


if __name__ == "__main__":
    if len(sys.argv) > 1:
        mif_file = sys.argv[1]
        view_mif_image(mif_file, IMAGE_WIDTH, IMAGE_HEIGHT)
    else:
        print(f"Usage: {sys.argv[0]} <mif_file_path>")
        print(f"Example: {sys.argv[0]} image.mif")
