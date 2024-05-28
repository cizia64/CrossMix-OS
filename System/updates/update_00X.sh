#!/bin/sh

# This will install python if it is somehow gone. :D

# HEADER
mkdir -p /etc/ex_update
UPDATE_DIR="/mnt/SDCARD/System/updates/$(basename "$0" | cut -d'.' -f 1)"
UPDATE_ID="$(basename "$UPDATE_DIR" | cut -d'_' -f 2)"

if [ -f "/mnt/SDCARD/System/bin/python3" ] && [ -f "/etc/ex_update/$UPDATE_ID" ]; then
    exit 0
fi

sdl2imgshow \
    -i "$EX_RESOURCE_PATH/background.png" \
    -f "$EX_RESOURCE_PATH/DejaVuSans.ttf" \
    -s 48 \
    -c "0,0,0" \
    -t "Installing TRIMUI_EX $UPDATE_ID" &

echo "--------------------------------------------"
echo "Running $0"
echo "- $UPDATE_DIR"
echo "- $UPDATE_ID"

# CONTENT

if [ ! -f "/mnt/SDCARD/System/bin/python3" ]; then
    # Unzip python
    unzip -o -d "/mnt/SDCARD/System/" "/mnt/SDCARD/System/updates/update_001/python.zip" > /mnt/SDCARD/System/updates/python.log
fi

# FOOTER
pkill -f sdl2imgshow

echo "Done!"
touch "/etc/ex_update/$UPDATE_ID"
