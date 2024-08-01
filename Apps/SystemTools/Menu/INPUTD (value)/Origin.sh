#!/usr/bin/env sh
script_name=$(basename "$0" .sh)


res_dir="/mnt/SDCARD/Apps/SystemTools/Resources/"
bin_dir="/usr/trimui/bin/"
file_name="trimui_inputd_unpatched"

if [ -L "$bin_dir/trimui_inputd" ]; then
	rm "$bin_dir/trimui_inputd"
else
	mv "$bin_dir/trimui_inputd" "$bin_dir/trimui_inputd.bak"
fi

if [ ! -f "$bin_dir$file_name" ]; then
    cp "$res_dir$file_name" "$bin_dir"
    chmod +x "$bin_dir$file_name"
fi

ln -s "$bin_dir$file_name" "$bin_dir/trimui_inputd"

# Menu modification to reflect the change immediately

# update crossmix.json configuration file
script_name=$(basename "$0" .sh)
json_file="/mnt/SDCARD/System/etc/crossmix.json"
if [ ! -f "$json_file" ]; then
  echo "{}" >"$json_file"
fi
jq --arg script_name "$script_name" '. += {"Inputd": $script_name}' "$json_file" >"/tmp/json_file.tmp" && mv "/tmp/json_file.tmp" "$json_file"


# update database of "System Tools" database
/mnt/SDCARD/System/usr/trimui/scripts/mainui_state_update.sh "Inputd" "$script_name"

/mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "You must reboot the device to apply the changes." -fs 22 -k "A B START SELECT"
