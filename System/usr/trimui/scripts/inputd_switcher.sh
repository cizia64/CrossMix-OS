#!/usr/bin/env sh
PATH="/mnt/SDCARD/System/bin:/mnt/SDCARD/System/usr/trimui/scripts:$PATH"
LD_LIBRARY_PATH="/mnt/SDCARD/System/lib:/usr/trimui/lib:$LD_LIBRARY_PATH"

script_name=$(basename "$0" .sh)
if [ "$script_name" = "inputd_switcher" ]; then
    scrip_name=$(/mnt/SDCARD/System/bin/jq -r '["POLLING_RATE"]' "/mnt/SDCARD/System/etc/crossmix.json")
fi
bin_dir="/mnt/SDCARD/trimui/app"

device="$(cat /mnt/SDCARD/System/usr/trimui/current_device.txt)"
if [ "$device" = "brick" ]; then
    rm -rf /mnt/SDCARD/trimui/app/trimui_inputd
    [ "$script_name" != "inputd_switcher" ] && infoscreen -m "Feature not supported yet on brick"
    exit 1
fi
inputd_src_dir=/mnt/SDCARD/System/resources/${device}_inputd

case "$script_name" in
"1ms")
    Sha_expected=c90b9fa722d745a7e827f38dbd409d3cd1ba56f5
    ;;
"8ms")
    Sha_expected=3f1b81d668c3f7de2cc0458502326a732d3cb0b2
    ;;
"16ms")
    Sha_expected=356b41b0be9d00f361e45303f41f5f1f337e6efc
    ;;
esac

Sha=$(sha1sum "$inputd_src_dir/$script_name" | cut -d ' ' -f 1)
if [ "$Sha_expected" = "$Sha" ]; then
    cp -f "$inputd_src_dir/$script_name" "$bin_dir/trimui_inputd"
    chmod +x "$bin_dir/trimui_inputd"
else
    infoscreen -m "Inputd switch failed: new inputd is corrupted."
    exit 1
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
