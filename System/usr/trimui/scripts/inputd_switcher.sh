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


cp /mnt/SDCARD/System/resources/${device}_inputd "$bin_dir/trimui_inputd"
chmod +x "$bin_dir/trimui_inputd"
sync


case "$polling_rate" in
"1ms")
    echo 1000 > "$bin_dir/inputd_polling_rate.cfg"
    ;;
"8ms")
    echo 8000 > "$bin_dir/inputd_polling_rate.cfg"
    ;;
"16ms")
    rm "$bin_dir/inputd_polling_rate.cfg"
    ;;
esac

sync


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
