#!/usr/bin/env python3
from PIL import Image
import os
import sys
import struct


def rrrgggbb_to_rgb(pixel_val_8bit):
    """
    Converts an 8-bit RRRGGGBB value back to a standard (R, G, B) tuple.
    Each channel in the output tuple ranges from 0-255.
    """
    # Extract RRR (bits 7-5), GGG (bits 4-2), BB (bits 1-0)
    rrr = (pixel_val_8bit >> 5) & 0x07
    ggg = (pixel_val_8bit >> 2) & 0x07
    bb = pixel_val_8bit & 0x03

    # Scale RRR (0-7) back to R8 (0-255)
    # This method distributes values well across the 0-255 range.
    # e.g. 0->0, 1->36, 2->73, ..., 7->255
    r8 = (rrr << 5) | (rrr << 2) | (rrr >> 1)

    # Scale GGG (0-7) back to G8 (0-255)
    g8 = (ggg << 5) | (ggg << 2) | (ggg >> 1)

    # Scale BB (0-3) back to B8 (0-255)
    # e.g. 0->0, 1->85, 2->170, 3->255
    b8 = (bb << 6) | (bb << 4) | (bb << 2) | bb

    return (r8, g8, b8)


def decompress_rle_data(compressed_file_path):
    """
    Decompresses RLE data from a file.
    Reads image dimensions (width, height) first, then the RLE data.
    Returns the decompressed RRRGGGBB byte sequence and dimensions.
    """
    try:
        with open(compressed_file_path, "rb") as f:
            # Read width and height (2 bytes each, big-endian)
            width_bytes = f.read(2)
            height_bytes = f.read(2)

            if len(width_bytes) < 2 or len(height_bytes) < 2:
                print("Error: Compressed file is too short to contain dimensions.")
                sys.exit(1)

            width = struct.unpack(">H", width_bytes)[0]
            height = struct.unpack(">H", height_bytes)[0]

            # Read the rest of the file as compressed data
            rle_data = f.read()

        decompressed_bytes = bytearray()
        i = 0
        while i < len(rle_data):
            if i + 1 >= len(rle_data):
                print(
                    "Error: RLE data seems truncated or malformed (missing count byte)."
                )
                break
            value_byte = rle_data[i]
            count = rle_data[i + 1]

            if (
                count == 0
            ):  # Should not happen with the current compressor (counts are 1-255)
                print(
                    "Warning: Encountered a run count of 0. This might indicate data corruption."
                )
                # If this occurs, it might be an error. For now, we'll skip this pair.
                i += 2
                continue

            decompressed_bytes.extend([value_byte] * count)
            i += 2

        expected_pixel_count = width * height
        if len(decompressed_bytes) != expected_pixel_count:
            print(
                f"Warning: Decompressed data size ({len(decompressed_bytes)} bytes) "
                f"does not match expected pixel count ({expected_pixel_count} for {width}x{height} image). "
                "Image might be incomplete or distorted."
            )
            # Pad or truncate if necessary for image creation, or let PIL handle it.
            # For now, we'll pass it as is.

        return bytes(decompressed_bytes), width, height
    except FileNotFoundError:
        print(f"Error: Compressed file not found at '{compressed_file_path}'")
        sys.exit(1)
    except struct.error as e:
        print(
            f"Error unpacking dimensions from '{compressed_file_path}': {e}. File might be corrupted."
        )
        sys.exit(1)
    except Exception as e:
        print(f"An unexpected error occurred during decompression: {e}")
        sys.exit(1)


def create_and_show_image(rrrgggbb_data, width, height, output_image_path=None):
    """
    Creates an image from the decompressed RRRGGGBB data,
    saves it to output_image_path (if provided), and displays it.
    """
    if not rrrgggbb_data or width == 0 or height == 0:
        print("Error: No data or invalid dimensions provided for image creation.")
        return

    rgb_pixels = []
    for pixel_val_8bit in rrrgggbb_data:
        rgb_pixels.append(rrrgggbb_to_rgb(pixel_val_8bit))

    # Ensure the number of pixels matches width * height for PIL
    expected_length = width * height
    if len(rgb_pixels) < expected_length:
        print(
            f"Warning: Pixel data is shorter ({len(rgb_pixels)}) than expected ({expected_length}). Padding with black."
        )
        rgb_pixels.extend([(0, 0, 0)] * (expected_length - len(rgb_pixels)))
    elif len(rgb_pixels) > expected_length:
        print(
            f"Warning: Pixel data is longer ({len(rgb_pixels)}) than expected ({expected_length}). Truncating."
        )
        rgb_pixels = rgb_pixels[:expected_length]

    try:
        img = Image.new("RGB", (width, height))
        img.putdata(rgb_pixels)

        print("Displaying reconstructed image...")
        img.show()  # Display the image

        if output_image_path:
            img.save(output_image_path)
            print(f"Reconstructed image saved to {output_image_path}")

    except Exception as e:
        print(f"Error creating or displaying image: {e}")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(
            "Usage: python testhex_compressed.py <compressed_hex_file> [output_image_file.png]"
        )
        sys.exit(1)

    compressed_hex_path = sys.argv[1]
    output_image_file = None  # Default is to just show the image

    if len(sys.argv) > 2:
        output_image_file = sys.argv[2]
    else:
        # Create a default output name if not specified, similar to original script's intent
        base, _ = os.path.splitext(compressed_hex_path)
        if base.endswith("_compressed"):
            base = base[: -len("_compressed")]  # e.g. "myimage_compressed" -> "myimage"
        output_image_file = base + "_reconstructed.png"

    print(f"Decompressing file: {compressed_hex_path}")
    rrrgggbb_pixel_data, width, height = decompress_rle_data(compressed_hex_path)

    if rrrgggbb_pixel_data:  # Check if decompression was successful
        print(
            f"Decompressed to {width}x{height}, {len(rrrgggbb_pixel_data)} RRRGGGBB pixels."
        )
        # The original script called view_hex_image with width and height,
        # which are now read from the file.
        create_and_show_image(rrrgggbb_pixel_data, width, height, output_image_file)
