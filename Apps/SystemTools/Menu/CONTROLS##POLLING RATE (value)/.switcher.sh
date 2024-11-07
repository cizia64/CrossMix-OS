#!/usr/bin/env sh
PATH="/mnt/SDCARD/System/bin:$PATH"
LD_LIBRARY_PATH="/mnt/SDCARD/System/lib:/usr/trimui/lib:$LD_LIBRARY_PATH"

script_name=$(basename "$0" .sh)
bin_dir="/usr/trimui/bin/"

if [ -f "$bin_dir/trimui_inputd.$script_name" ]; then
  cp -f "$bin_dir/trimui_inputd.$script_name" "$bin_dir/trimui_inputd"
fi

# Menu modification to reflect the change immediately

# update crossmix.json configuration file
json_file="/mnt/SDCARD/System/etc/crossmix.json"
if [ ! -f "$json_file" ]; then
  echo "{}" >"$json_file"
fi
jq --arg script_name "$script_name" '. += {"POLLING RATE": $script_name}' "$json_file" >"/tmp/json_file.tmp" && mv "/tmp/json_file.tmp" "$json_file"


# update database of "System Tools" database
/mnt/SDCARD/System/usr/trimui/scripts/mainui_state_update.sh "POLLING RATE" "$script_name"

/mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "Applying $(basename "$0" .sh) polling rate..." -t 1
pkill trimui_inputd
pkill -KILL MainUI
