#!/bin/bash

config_file="$1"
shift 1

if [ "$#" -lt 2 ] || [ $(($# % 2)) -ne 0 ]; then
    echo "Usage: $0 <config_file> <key1> <value1> [<key2> <value2> ...]"
    exit 1
fi

if [ ! -f "$config_file" ]; then
    echo "Config file $config_file does not exist."
    exit 1
fi

# Loop through pairs of key-value arguments
while [ "$#" -ge 2 ]; do
    key="$1"
    value="$2"

    # Format the value with quotes if necessary
    formatted_value=$(echo "$value" | sed 's/^"\(.*\)"$/\1/')

    # Check if the key already exists in the file
    if grep -q "^[[:space:]]*$key[[:space:]]*=" "$config_file"; then
        # If the key exists, adjust the format with a space before the equals sign and quotes around the value
        sed -i 's/^[[:space:]]*'"$key"'[[:space:]]*=[[:space:]]*".*"/'"$key"' = "'"$formatted_value"'"/' "$config_file"
    else
        # If the key does not exist, add a new line with the correct format (space before the equals sign and quotes)
        echo "$key = \"$formatted_value\"" >> "$config_file"
    fi

    echo "Updated $config_file with $key = \"$formatted_value\""

    shift 2
done
