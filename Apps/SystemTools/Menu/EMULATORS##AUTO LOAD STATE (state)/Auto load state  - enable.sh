#!/bin/sh
PATH="/mnt/SDCARD/System/bin:$PATH"
LD_LIBRARY_PATH="/mnt/SDCARD/System/lib:/usr/trimui/lib:$LD_LIBRARY_PATH"

/mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "Applying \"$(basename "$0" .sh)\" by default..."

/mnt/SDCARD/System/usr/trimui/scripts/set_ra_cfg.sh "/mnt/SDCARD/RetroArch/retroarch.cfg"  "savestate_auto_load" "true"

json_file="/mnt/SDCARD/System/etc/crossmix.json"
if [ ! -f "$json_file" ]; then
    echo "{}" >"$json_file"
fi

/mnt/SDCARD/System/bin/jq '. += {"AUTO LOAD STATE": 1}' "$json_file" >"/tmp/json_file.tmp" && mv "/tmp/json_file.tmp" "$json_file"

# Menu modification to reflect the change immediately
/mnt/SDCARD/System/usr/trimui/scripts/mainui_state_update.sh "AUTO LOAD STATE" "enabled"