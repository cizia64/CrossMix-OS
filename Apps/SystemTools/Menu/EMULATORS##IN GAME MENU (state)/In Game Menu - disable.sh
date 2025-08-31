#!/bin/sh
export PATH="/mnt/SDCARD/System/usr/trimui/scripts/:/mnt/SDCARD/System/bin:${PATH:+:$PATH}"
export LD_LIBRARY_PATH="/mnt/SDCARD/System/lib:/usr/trimui/lib:$LD_LIBRARY_PATH"

infoscreen.sh -m "Applying \"$(basename "$0" .sh)\" by default..."

json_file="/mnt/SDCARD/System/etc/crossmix.json"

if [ ! -f "$json_file" ]; then
    echo "{}" >"$json_file"
fi

jq '. += {"IN GAME MENU": 0}' "$json_file" >"/tmp/json_file.tmp" && mv "/tmp/json_file.tmp" "$json_file"

mkdir -p /tmp/trimui_ra64/
touch /tmp/trimui_ra64/disable_tmenu

# we modify the DB entries to reflect the current state
mainui_state_update.sh "IN GAME MENU" "disabled"
