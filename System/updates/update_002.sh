#!/bin/sh

# HEADER
mkdir -p /etc/ex_update
UPDATE_DIR="/mnt/SDCARD/System/updates/$(basename "$0" | cut -d'.' -f 1)"
UPDATE_ID="$(basename "$UPDATE_DIR" | cut -d'_' -f 2)"

if [ -f "/etc/ex_update/$UPDATE_ID" ]; then
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

# Add sftp-server
mkdir -p /usr/libexec/
cp -vf "$UPDATE_DIR/sftp-server" /usr/libexec/sftp-server

# FOOTER
pkill -f sdl2imgshow

echo "Done!"
touch "/etc/ex_update/$UPDATE_ID"
