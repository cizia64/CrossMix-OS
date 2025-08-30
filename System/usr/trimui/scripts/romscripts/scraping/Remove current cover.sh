# Check that variables are defined and not empty
if [ -z "$EMU_DIR" ] || [ -z "$ROM_FILENAME_NOEXT" ]; then
    echo "Error: EMU_DIR or ROM_FILENAME_NOEXT is empty."
    exit 1
fi

IMG_DIR="/mnt/SDCARD/Imgs/$(basename "$EMU_DIR")"
IMG_PNG="$IMG_DIR/$ROM_FILENAME_NOEXT.png"
IMG_JPG="$IMG_DIR/$ROM_FILENAME_NOEXT.jpg"

# Delete the image if it exists
if [ -f "$IMG_PNG" ]; then
    rm "$IMG_PNG"
    echo "Deleted: $IMG_PNG"
elif [ -f "$IMG_JPG" ]; then
    rm "$IMG_JPG"
    echo "Deleted: $IMG_JPG"
else
    echo "No image found for $ROM_FILENAME_NOEXT"
fi

sync
