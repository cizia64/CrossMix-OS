#!/bin/bash

config_file="$1"
key="$2"

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <config_file> <key>"
    exit 1
fi

if [ ! -f "$config_file" ]; then
    echo "Config file $config_file does not exist."
    exit 1
fi

# Extract the value of the key from the configuration file
value=$(grep "^[[:space:]]*$key[[:space:]]*=" "$config_file" | sed 's/^[[:space:]]*'"$key"'[[:space:]]*=[[:space:]]*"*\([^"]*\)"*/\1/')

if [ -z "$value" ]; then
    echo "Key '$key' not found in $config_file"
else
    echo "$key = \"$value\""
fi
