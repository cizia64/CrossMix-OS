#!/bin/sh
PATH="/mnt/SDCARD/System/bin:$PATH"
LD_LIBRARY_PATH="/mnt/SDCARD/System/lib:/usr/trimui/lib:$LD_LIBRARY_PATH"

silent=false
for arg in "$@"; do
  if [ "$arg" = "-s" ]; then
    silent=true
    break
  fi
done

script_name=$(basename "$0" .sh)

if [ "$silent" = false ]; then
  /mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "$script_name by default."
fi

read -r current_device </etc/trimui_device.txt

tabN=${script_name#* }
tabN=$((tabN - 1))
tab0=0

if [ "$current_device" = tsp ] && [ "$tabN" -gt 2 ]; then
    tab0=$((tabN - 2))
elif [ "$current_device" = brick ] && [ "$tabN" -gt 4 ]; then
    tab0=$((tabN - 4))
fi

jq ".[].[1].tabidx = $tabN | .[].[1].tabstartidx = $tab0" /mnt/SDCARD/System/resources/default_state.json > /tmp/tmp.json
mv /tmp/tmp.json /mnt/SDCARD/System/resources/default_state.json

# Menu modification to reflect the change immediately

# update crossmix.json configuration file
json_file="/mnt/SDCARD/System/etc/crossmix.json"
if [ ! -f "$json_file" ]; then
  echo "{}" >"$json_file"
fi
jq --arg script_name "$script_name" '. += {"START TAB": $script_name}' "$json_file" >"/tmp/json_file.tmp" && mv "/tmp/json_file.tmp" "$json_file"

# update database of "System Tools" database
/mnt/SDCARD/System/usr/trimui/scripts/mainui_state_update.sh "START TAB" "$script_name"
