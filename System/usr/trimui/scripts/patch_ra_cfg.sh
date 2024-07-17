#!/bin/sh
patch="$1"
config="$2"

# Use default config path if not provided
if [ "$config" = "" ]; then
    config=/mnt/SDCARD/RetroArch/retroarch.cfg
fi

# Check if the patch file exists
if [ ! -f "$patch" ]; then
    echo "Patch file doesn't exist"
    exit 1
fi

# Check if the config file exists
if [ ! -f "$config" ]; then
    echo "Config file doesn't exist"
    exit 1
fi

# Ensure the patch file ends with a newline
if [ "$(tail -c1 "$patch")" != "" ]; then
    echo >> "$patch"
fi

# Read the patch file and apply changes to the config file
cat "$patch" | (
    count=0
    content=$(cat "$config")

    while read -r line; do
        key=$(echo "$line" | sed 's/^\s*//g' | sed 's/\s*=.*$//g')
        value=$(echo "$line" | sed 's/^[^\"]*"//g' | sed 's/"[^\"]*$//g')

        if echo "$content" | grep -q "^\s*$key\s*="; then
            content=$(echo "$content" | sed "/$key\s*=/c$key = \"$value\"")
        else
            content="$content
$key = \"$value\""
        fi

        count=$((count + 1))
    done

    echo "$content" > "$config"

    echo "$count lines patched"
)
sync
