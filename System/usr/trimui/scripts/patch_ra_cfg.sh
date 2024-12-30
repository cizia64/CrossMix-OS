#!/bin/sh

# Input files
PATCH_FILE="$1"
TARGET_FILE="${2:-/mnt/SDCARD/RetroArch/retroarch.cfg}"

# Check if the files exist
for file in "$PATCH_FILE" "$TARGET_FILE"; do
    if [ ! -f "$file" ]; then
        echo "$file doesn't exist"
        exit 1
    fi
done

# Ensure the patch file ends with a newline
if [ "$(tail -c1 "$PATCH_FILE")" != "" ]; then
    echo >> "$PATCH_FILE"
fi

# Create a temporary file for the patched target
TMP_FILE=$(mktemp)

# Use awk to process the files
awk -F= -v OFS="=" -v patch="$PATCH_FILE" '
    BEGIN {
        # Read the patch file into a map
        while ((getline < patch) > 0) {
            if ($1 ~ /^[[:space:]]*$/ || $1 ~ /^#/) continue; # Skip empty lines or comments
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", $1); # Trim spaces
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2); # Trim spaces
            patch_map[$1] = $2; # Store key-value pairs
        }
        close(patch);
    }
    {
        key = $1;
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", key); # Trim spaces
        if (key in patch_map) {
            # Update existing key with patched value
            $2 = patch_map[key];
            delete patch_map[key]; # Mark key as processed
        }
        print $1, $2;
    }
    END {
        # Append remaining keys from the patch file
        for (key in patch_map) {
            print key, patch_map[key];
        }
    }
' "$TARGET_FILE" > "$TMP_FILE"

# Replace the target file with the updated content
mv "$TMP_FILE" "$TARGET_FILE"

# Output summary
echo "Patched $(wc -l < "$PATCH_FILE") lines in $(basename "$TARGET_FILE")."
sync
