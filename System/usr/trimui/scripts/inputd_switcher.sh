#!/usr/bin/env sh
PATH="/mnt/SDCARD/System/bin:/mnt/SDCARD/System/usr/trimui/scripts:$PATH"
LD_LIBRARY_PATH="/mnt/SDCARD/System/lib:/usr/trimui/lib:$LD_LIBRARY_PATH"

script_name=$(basename "$0" .sh)
if [ "$script_name" = "inputd_switcher" ]; then
    polling_rate=$(/mnt/SDCARD/System/bin/jq -r '.["POLLING RATE"]' "/mnt/SDCARD/System/etc/crossmix.json")
else
    polling_rate=$script_name
fi

bin_dir="/mnt/SDCARD/trimui/app"

read -r device < /etc/trimui_device.txt
if [ "$device" = "brick" ]; then
    cp /usr/trimui/bin/trimui_inputd $bin_dir/trimui_inputd
    [ "$script_name" != "inputd_switcher" ] && infoscreen -m "Feature not supported yet on brick"
    exit 1
fi

inputd_src_dir=/mnt/SDCARD/System/resources/${device}_inputd
[ -f "$inputd_src_dir/$polling_rate" ] || polling_rate=16ms

case "$polling_rate" in
"1ms")
    Sha_expected=93454518ccacd4d3ffe22b0811cae0ac3c00a714
    ;;
"8ms")
    Sha_expected=306d1693d4da4257eb0b7bcf13ec113019b87e69
    ;;
"16ms")
    Sha_expected=1f15184d75911c115bac9fc7cab8d79d4f311bf4
    ;;
esac

Sha=$(sha1sum "$inputd_src_dir/$polling_rate" | cut -d ' ' -f 1)
if [ "$Sha_expected" = "$Sha" ]; then
    cp -f "$inputd_src_dir/$polling_rate" "$bin_dir/trimui_inputd"
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
jq --arg polling_rate "$polling_rate" '. += {"POLLING RATE": $polling_rate}' "$json_file" >"/tmp/json_file.tmp" && mv "/tmp/json_file.tmp" "$json_file"

# update database of "System Tools" database
/mnt/SDCARD/System/usr/trimui/scripts/mainui_state_update.sh "POLLING RATE" "$polling_rate"

/mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "Applying $polling_rate polling rate..." -t 1
pkill trimui_inputd
pkill -KILL MainUI
