#!/usr/bin/env sh

export PATH="/mnt/SDCARD/System/usr/trimui/scripts/:$PATH"

res_dir=/mnt/SDCARD/Apps/SystemTools/Resources
bin_dir=/usr/trimui/bin
script_name=$(basename "$0" .sh)

case $script_name in
"Origin")
	new_inputd=trimui_inputd_unpatched
	expected_sha1=ab951f80ad78b069e1910b13d053a7ea118e30c6
	;;
"Patched_1ms")
	new_inputd=trimui_inputd_patched_1ms
	expected_sha1=c1a188935ed482967ae43cfb214f2a27ab24a06a
	;;
"Patched_14ms")
	new_inputd=trimui_inputd_patched_14ms
	expected_sha1=a0ec483bc74034471c5782559351f43db9937ed1
	;;
esac

sys_sha1=$(sha1sum "$bin_dir/$new_inputd")
card_sha1=$(sha1sum "$res_dir/$new_inputd")

# Copy the new inputd to the bin directory
if [ ! -f "$bin_dir/$new_inputd" ] || [ "${sys_sha1%% *}" != "$expected_sha1" ]; then
	if [ "${card_sha1%% *}" != "$expected_sha1" ]; then
		infoscreen.sh -m "The file $new_inputd is missing or corrupted." -fs 22 -k "A B START SELECT"
		exit 1
	fi
	cp "$res_dir/$new_inputd" "$bin_dir/"
	chmod +x "$bin_dir/$new_inputd"
fi

# Bakup the original inputd or remove if it is already a symbolic link
if [ -L "$bin_dir/trimui_inputd" ]; then
	rm "$bin_dir/trimui_inputd"
else
	mv "$bin_dir/trimui_inputd" "$bin_dir/trimui_inputd.bak"
fi

# Create a symbolic link to the new inputd
ln -s "$bin_dir/$new_inputd" "$bin_dir/trimui_inputd"

# Menu modification to reflect the change immediately

# Update crossmix.json configuration file
json_file="/mnt/SDCARD/System/etc/crossmix.json"
if [ ! -f "$json_file" ]; then
	echo "{}" >"$json_file"
fi
jq --arg script_name "$script_name" '. += {"STICK FIX": $script_name}' "$json_file" >"/tmp/json_file.tmp" && mv "/tmp/json_file.tmp" "$json_file"

# Update database of "System Tools" database
mainui_state_update.sh "STICK FIX" "$script_name"

infoscreen.sh -m "You must reboot the device to apply the changes." -fs 22 -k "A B START SELECT"
