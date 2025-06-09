#!/usr/bin/env python3
from PIL import Image
import sys

# --- Configuration ---
# Set your image's dimensions here
IMAGE_WIDTH = 50
IMAGE_HEIGHT = 50
# --- End Configuration ---


def hex_to_rgb(pixel_val):
    """
    Converts a 1-bit pixel value to an (R, G, B) tuple.
    1 (black) -> (0, 0, 0)
    0 (white) -> (255, 255, 255)
    """
    return (0, 0, 0) if pixel_val else (255, 255, 255)


def view_1bit_mif_image(mif_file_path, width, height):
    """
    Reads a .mif file where each line contains an 8-bit hex value,
    with each bit representing a single pixel, and displays it as an image.
    """
    try:
        with open(mif_file_path, "r") as f:
            # Read lines, strip whitespace, and filter out comments and empty lines
            mif_lines = [
                line.strip()
                for line in f.read().splitlines()
                if line.strip() and not line.strip().startswith(("//", "--"))
            ]
    except FileNotFoundError:
        print(f"Error: MIF file '{mif_file_path}' not found.")
        return
    except Exception as e:
        print(f"Error reading MIF file: {e}")
        return

    if not mif_lines:
        print("Error: MIF file is empty or contains no valid data lines.")
        return

    rgb_pixels = []
    total_pixels_expected = width * height
    pixels_processed = 0

    # Process each data line from the MIF file
    for line in mif_lines:
        if pixels_processed >= total_pixels_expected:
            break  # Stop if we already have enough pixels for the image

        # Split address and value, e.g., "00 : AB;" -> "00", "AB;"
        try:
            _, hex_part = line.split(":", 1)
            # Clean up the hex value part, removing whitespace and semicolon
            hex_byte_str = hex_part.strip().rstrip(";")
        except ValueError:
            print(f"Warning: Invalid MIF line format, skipping: '{line}'")
            continue

        # Ensure the hex value is a single byte (2 characters)
        if len(hex_byte_str) != 2:
            print(
                f"Warning: Expected 2-character hex value, but got '{hex_byte_str}'. Skipping line."
            )
            continue

        try:
            byte_val = int(hex_byte_str, 16)
        except ValueError:
            print(
                f"Warning: Invalid hex byte string '{hex_byte_str}' encountered. Skipping."
            )
            continue

        # Extract 8 pixels (bits) from this byte, MSB first
        for bit_pos in range(7, -1, -1):
            if pixels_processed >= total_pixels_expected:
                break

            pixel_bit = (byte_val >> bit_pos) & 1  # Get the bit (0 or 1)
            rgb_pixels.append(hex_to_rgb(pixel_bit))
            pixels_processed += 1

    # --- Image Generation and Warnings ---
    if not rgb_pixels:
        print("Error: No pixels were decoded from the MIF file.")
        return

    # Check if the provided data was sufficient
    if pixels_processed < total_pixels_expected:
        print(
            f"Warning: MIF data provided {pixels_processed} pixels, "
            f"but {total_pixels_expected} were expected for a {width}x{height} image. "
            "Image will be padded with white pixels."
        )
        # Pad with white pixels to complete the image
        padding_needed = total_pixels_expected - len(rgb_pixels)
        rgb_pixels.extend([hex_to_rgb(0)] * padding_needed)

    # Create the image using the Pillow library
    try:
        img = Image.new("RGB", (width, height))
        img.putdata(rgb_pixels)
        img.show()
        print(f"Displaying 1-bit image from '{mif_file_path}' ({width}x{height}).")
    except Exception as e:
        print(f"Error creating or displaying image: {e}")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print(f"Usage: python {sys.argv[0]} <path_to_mif_file>")
        sys.exit(1)

    mif_file = sys.argv[1]
    view_1bit_mif_image(mif_file, IMAGE_WIDTH, IMAGE_HEIGHT)
