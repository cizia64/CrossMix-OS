#!/usr/bin/env sh

res_dir="/mnt/SDCARD/Apps/SystemTools/Resources/"
bin_dir="/usr/trimui/bin/"
script_name=$(basename "$0" .sh)

case $script_name in
"Origin")
	new_inputd="trimui_inputd_unpatched"
	;;
"Patched_1ms")
	new_inputd="trimui_inputd_patched_1ms"
	;;
"Patched_14ms")
	new_inputd="trimui_inputd_patched_14ms"
	;;
esac

# Bakup the original inputd or remove if it is already a symbolic link
if [ -L "$bin_dir/trimui_inputd" ]; then
	rm "$bin_dir/trimui_inputd"
else
	mv "$bin_dir/trimui_inputd" "$bin_dir/trimui_inputd.bak"
fi

# Copy the new inputd to the bin directory
if [ ! -f "$bin_dir$new_inputd" ]; then
	cp "$res_dir$new_inputd" "$bin_dir"
	chmod +x "$bin_dir$new_inputd"
fi

# Create a symbolic link to the new inputd
ln -s "$bin_dir$new_inputd" "$bin_dir/trimui_inputd"

# Menu modification to reflect the change immediately

# Update crossmix.json configuration file
json_file="/mnt/SDCARD/System/etc/crossmix.json"
if [ ! -f "$json_file" ]; then
	echo "{}" >"$json_file"
fi
jq --arg script_name "$script_name" '. += {"INPUTD": $script_name}' "$json_file" >"/tmp/json_file.tmp" && mv "/tmp/json_file.tmp" "$json_file"

export PATH="/mnt/SDCARD/System/usr/trimui/scripts/"

# Update database of "System Tools" database
mainui_state_update.sh "Inputd" "$script_name"

infoscreen.sh -m "You must reboot the device to apply the changes." -fs 22 -k "A B START SELECT"
