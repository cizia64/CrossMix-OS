#!/bin/sh

patch="$1"
config="${2:-/mnt/SDCARD/RetroArch/retroarch.cfg}"

# Check if the files exist
for file in "$patch" "$config"; do
    if [ ! -f "$file" ]; then
        echo "$file doesn't exist"
        exit 1
    fi
done

# Ensure the patch file ends with a newline
if [ "$(tail -c1 "$patch")" != "" ]; then
    echo >> "$patch"
fi

# Apply patch modifications to the configuration file
count=0
content=$(cat "$config")

while IFS='=' read -r key value; do
    key=$(echo "$key" | xargs)

    # Check if the value is quoted
    quoted=0
    if echo "$value" | grep -q '^"'; then
        value=$(echo "$value" | sed 's/^"\(.*\)"$/\1/')
        quoted=1
    fi

    # Check if the key exists in the config file
    if echo "$content" | grep -Eq "^\s*${key}\s*="; then
        original_line=$(echo "$content" | grep -E "^\s*${key}\s*=")

        # Check if the original line has spaces before the equal sign
        if echo "$original_line" | grep -q '\s='; then
            # Keep the quotes if the value was originally quoted
            if [ "$quoted" -eq 1 ]; then
                content=$(echo "$content" | sed -E "s|^\s*${key}\s*=.*|${key} = \"$value\"|")
            else
                content=$(echo "$content" | sed -E "s|^\s*${key}\s*=.*|${key} = $value|")
            fi
        else
            # Keep the quotes if the value was originally quoted
            if [ "$quoted" -eq 1 ]; then
                content=$(echo "$content" | sed -E "s|^\s*${key}\s*=.*|${key}=\"$value\"|")
            else
                content=$(echo "$content" | sed -E "s|^\s*${key}\s*=.*|${key}=$value|")
            fi
        fi
    else
        # Add the key if it doesn't exist
        if [ "$quoted" -eq 1 ]; then
            content="$content\n${key} = \"$value\""
        else
            content="$content\n${key}=$value"
        fi
    fi
    count=$((count + 1))
done < "$patch"

# Write the updated content back to the configuration file
echo -e "$content" > "$config"
echo "$count lines patched"
sync
