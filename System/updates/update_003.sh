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
DEVICE_FILE="/etc/trimui_device.txt"
DEVICE_ID=""
if [ -f "$DEVICE_FILE" ]; then
    DEVICE_ID="$(tr '[:upper:]' '[:lower:]' < "$DEVICE_FILE" | tr -d '\r\n')"
fi

if [ "$DEVICE_ID" != "tsp" ]; then
    echo "Skipping PPSSPP setup: device is '$DEVICE_ID', expected 'tsp'."
else
    echo "Starting PPSSPP setup..."
    UTILS_DIR="/mnt/SDCARD/utils"
    SETUP_SCRIPT="$UTILS_DIR/ppsspp_setup.sh"
    if [ ! -f "$SETUP_SCRIPT" ]; then
        echo "PPSSPP setup script not found: $SETUP_SCRIPT"
    else
        echo "Launching PPSSPP setup..."
        if command -v bash >/dev/null 2>&1; then
            (cd "$UTILS_DIR" && bash "$SETUP_SCRIPT")
        else
            (cd "$UTILS_DIR" && sh "$SETUP_SCRIPT")
        fi

        # Check the exit status of the setup script
        setup_status=$?
        if [ "$setup_status" -ne 0 ]; then
            echo "PPSSPP setup failed with status $setup_status."
        fi
    fi
fi

# FOOTER
pkill -f sdl2imgshow

echo "Done!"
touch "/etc/ex_update/$UPDATE_ID"
