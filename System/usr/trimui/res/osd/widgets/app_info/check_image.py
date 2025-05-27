from PIL import Image
import os
import sys

image_path = "/tmp/crossmix_info/app_info.png"

try:
    with Image.open(image_path) as img:
        if img.format != "PNG":
            print(f"Invalid format: {img.format} (expected PNG). Deleting file.")
            os.remove(image_path)
            sys.exit(1)

        if img.size != (260, 260):
            print(f"Invalid size: {img.size} (expected 260x260). Deleting file.")
            os.remove(image_path)
            sys.exit(1)

        print("Image is a valid 260x260 PNG.")
except FileNotFoundError:
    print(f"File not found: {image_path}")
    sys.exit(1)
except Exception as e:
    print(f"Error: {e}. Deleting file if it exists.")
    if os.path.exists(image_path):
        os.remove(image_path)
    sys.exit(1)
