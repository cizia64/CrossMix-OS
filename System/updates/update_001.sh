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

# Add ssl certs.
mkdir -p /etc/ssl/certs/
cp -vf "$UPDATE_DIR/ca-certificates.crt" /etc/ssl/certs/

# Install new busybox
cp -vf /bin/busybox /mnt/SDCARD/System/bin/busybox.bak
/mnt/SDCARD/System/bin/rsync /mnt/SDCARD/System/usr/trimui/scripts/busybox /bin/busybox

ln -vs "/bin/busybox" "/bin/bash"

# Create missing busybox commands
for cmd in $(busybox --list); do
    # Skip if command already exists or if it's not suitable for linking
    if [ -e "/bin/$cmd" ] || [ -e "/usr/bin/$cmd" ] || [ "$cmd" = "sh" ]; then
        continue
    fi

    # Create a symbolic link
    ln -vs "/bin/busybox" "/usr/bin/$cmd"
done

# Fix weird libSDL location
for libname in /usr/trimui/lib/libSDL*; do
    linkname="/usr/lib/$(basename "$libname")"
    if [ -e "$linkname" ]; then
        continue
    fi
    ln -vs "$libname" "$linkname"
done

# Unzip python
unzip -o -d "/mnt/SDCARD/System/" "$UPDATE_DIR/python.zip" > /mnt/SDCARD/System/updates/python.log

# FOOTER
pkill -f sdl2imgshow

echo "Done!"
touch "/etc/ex_update/$UPDATE_ID"
