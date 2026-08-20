#!/bin/sh

# Check arguments
CURRENT_DEVICE="$1"

if [ -z "$CURRENT_DEVICE" ]; then
    echo "Usage: $0 <device_name>"
    echo "Device name must be one of: tsp, tsps, brick, brickpro"
    exit 1
fi

# Define paths
PATCH_DIR="/mnt/SDCARD/trimui/res/lang"
TARGET_DIR="/usr/trimui/res/lang"
REF_DIR="/mnt/SDCARD/trimui/res/lang"

echo "Applying patches for device: $CURRENT_DEVICE"

# Ensure target directory exists
mkdir -p "$TARGET_DIR"

# Find all patch files for the current device
# Pattern: *.device.patch
for patch_path in "$PATCH_DIR"/*."$CURRENT_DEVICE".patch; do
    # Check if glob matched anything
    if [ ! -e "$patch_path" ]; then
        echo "No patches found for device $CURRENT_DEVICE in $PATCH_DIR"
        break
    fi

    filename=$(basename "$patch_path")
    # Extract language code. Assuming format lang.device.patch
    # We want everything before the first dot.
    lang_code=${filename%%.*}

    source_file="$REF_DIR/$lang_code.lang"
    target_file="$TARGET_DIR/$lang_code.lang"

    if [ -f "$source_file" ]; then
        echo "Patching $lang_code..."

        # Use python3 to apply the patch
        python3 -c "
import sys
import json
import os

source_path = sys.argv[1]
patch_path = sys.argv[2]
target_path = sys.argv[3]

try:
    with open(source_path, 'r', encoding='utf-8') as f:
        data = json.load(f)

    with open(patch_path, 'r', encoding='utf-8') as f:
        patch_data = json.load(f)

    # Remove keys >= 197 from data that are not in the patch
    # This ensures that if we switch devices, we don't keep keys from the previous device
    keys_to_remove = []
    for key in list(data.keys()):
        if key.isdigit() and int(key) >= 197:
            if key not in patch_data:
                keys_to_remove.append(key)
    
    for key in keys_to_remove:
        del data[key]

    # Apply patch
    # The patch contains keys that should be updated in the target
    for key, value in patch_data.items():
        data[key] = value

    # Write to target file
    with open(target_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=4, ensure_ascii=False)

except Exception as e:
    print(f'Error applying patch for {source_path}: {e}')
    sys.exit(1)
" "$source_file" "$patch_path" "$target_file"

    else
        echo "Skipping $filename: Reference file $source_file not found."
    fi
done

echo "Done."
