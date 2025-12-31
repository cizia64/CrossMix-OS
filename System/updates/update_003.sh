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
HOSTNAME="$(hostname 2>/dev/null || echo "")"
HOST_UPPER="$(printf '%s' "$HOSTNAME" | tr '[:lower:]' '[:upper:]')"
if [ "$HOST_UPPER" != "TSP" ]; then
    echo "Skipping PPSSPP setup: hostname is '$HOSTNAME', expected 'TSP'."
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
    fi
fi

# FOOTER
pkill -f sdl2imgshow

echo "Done!"
touch "/etc/ex_update/$UPDATE_ID"
