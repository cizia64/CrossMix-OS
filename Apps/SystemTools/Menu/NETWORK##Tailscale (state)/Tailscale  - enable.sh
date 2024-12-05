#!/bin/sh

RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
NONE="\033[0m"

# Paths and environment variables
PATH="/mnt/SDCARD/System/bin:$PATH"
export LD_LIBRARY_PATH="/mnt/SDCARD/System/lib:/usr/trimui/lib:$LD_LIBRARY_PATH"

TAILSCALED="/mnt/SDCARD/System/bin/tailscaled"
TAILSCALE="/mnt/SDCARD/System/bin/tailscaled"
TAILSCALED_STATE_FILE="/mnt/SDCARD/System/etc/tailscale/tailscaled.state"
JSON_FILE="/mnt/SDCARD/System/etc/crossmix.json"
LOGIN_LOG="/mnt/SDCARD/System/etc/tailscale/login.txt"
export STATE_DIRECTORY=/mnt/SDCARD/System/etc/tailscale
URL="https://github.com/cizia64/CrossMix-OS/raw/refs/heads/main/_assets/resources/tailscale.7z"

# Check internet connection

echo -e "\n${YELLOW}Checking internet connection...${NONE}"
echo "-------------------------------"
if /mnt/SDCARD/System/bin/wget -q --spider https://github.com >/dev/null; then
    echo -e "${GREEN}OK${NONE}"
else
    /mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "github.com not reachable. Check your wifi connection !" -k "A B" -i bg-exit.png
    exit
fi

if [ ! -f "$TAILSCALE" ] || [ ! -f "$TAILSCALED" ]; then
    wget -q -O /tmp/tailscale.7z "$URL"
    if [ $? -eq 0 ]; then
        /mnt/SDCARD/System/bin/7zz x /tmp/tailscale.7z -o"/mnt/SDCARD" -y
        rm /tmp/tailscale.7z
    fi
fi

# Display initial notification
echo -e "${BLUE}Applying \"$(basename "$0" .sh)\" by default...${NONE}"
/mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "Applying \"$(basename "$0" .sh)\" by default..."

# Create JSON file if missing
[ ! -f "$JSON_FILE" ] && echo "{}" >"$JSON_FILE"

# Update JSON file
/mnt/SDCARD/System/bin/jq '. += {"Tailscale": 1}' "$JSON_FILE" >"/tmp/json_file.tmp" && mv "/tmp/json_file.tmp" "$JSON_FILE"

# Stop any existing Tailscale process and start it with the state file
pkill -9 "$TAILSCALED"
pkill -9 "$TAILSCALE"

mkdir -p "$STATE_DIRECTORY"

$TAILSCALED --state="$TAILSCALED_STATE_FILE" >/dev/null &

# Function to terminate text_viewer on button EMNU press
text_viewer_killer() {
    while true; do
        button=$(/mnt/SDCARD/System/usr/trimui/scripts/getkey.sh "MENU" 2>/dev/null)
        if [ "$button" = "MENU" ]; then
            echo "Exiting text_viewer."
            pkill -9 text_viewer
            /mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "Exiting Tailscale connect page..."
            break
        fi
    done
}
tailscale_new_up() {
    echo "" >"$LOGIN_LOG"
    /mnt/SDCARD/System/bin/tailscale up --qr >>"$LOGIN_LOG" 2>&1 &
    sleep 1
    sync
    echo "Press MENU to exit." >>"$LOGIN_LOG"

    /mnt/SDCARD/System/bin/text_viewer -t "Tailscale device login information" -s "tail -n 100 -f /mnt/SDCARD/System/etc/tailscale/login.txt" &

    text_viewer_killer &
    text_viewer_killer_PID=$!
    while [ -e /proc/$text_viewer_killer_PID ] && ! check_tailscale_status; do
        echo "Waiting for Tailscale to connect..."
    done
    kill "$text_viewer_killer_PID" 2>/dev/null
    pkill -9 getkey.sh
    pkill -9 text_viewer
}

# Function to check Tailscale status
check_tailscale_status() {
    for i in $(seq 1 10); do
        if /mnt/SDCARD/System/bin/tailscale status >/dev/null 2>&1; then
            return 0
        fi
        sleep 1
    done
    echo -e "${RED}Tailscale is not connected.${NONE}"
    return 1
}

# Function to handle "tailscale status" output
handle_status_output() {
    local status_output
    status_output=$(/mnt/SDCARD/System/bin/tailscale status 2>&1)

    if echo "$status_output" | grep -q "Tailscale is starting"; then
        echo -e "${YELLOW}Tailscale is starting. Retrying...${NONE}"
        return 1
    elif echo "$status_output" | grep -q "Logged out"; then
        echo -e "${RED}Tailscale is logged out.${NONE}\n${YELLOW}Starting login procedure...${NONE}"
        tailscale_new_up
        return 1
    fi
    return 0
}

# Main logic to check and start Tailscale
if jq -e 'has("_current-profile")' "$TAILSCALED_STATE_FILE" >/dev/null; then
    echo -e "${GREEN}_current-profile is present.${NONE}"
    echo "Checking current tailscale state..."
    if ! check_tailscale_status; then # We check the Tailscale status 10 times
        echo -e "${RED}Tailscale is not connected. Checking status output...${NONE}"
        handle_status_output
    fi
else
    echo -e "${RED}_current-profile is missing.${NONE}\n${YELLOW}Starting login procedure...${NONE}"
    tailscale_new_up
fi

# Update main UI state
/mnt/SDCARD/System/usr/trimui/scripts/mainui_state_update.sh "Tailscale" "enabled"

# Display final notification
if ! check_tailscale_status; then
    echo -e "${RED}Tailscale not configured or connected.${NONE}"
    /mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "Tailscale enabled but not configured / connected." -k "A" -t 1
else
    echo -e "${GREEN}Tailscale enabled successfully.${NONE}"
    CURRENT_IP=$(/mnt/SDCARD/System/bin/tailscale status --json | jq -r '.Self.TailscaleIPs[0]')
    echo "$CURRENT_IP"

    /mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "Tailscale enabled: $CURRENT_IP" -k "A" -i bg-exit.png
fi
