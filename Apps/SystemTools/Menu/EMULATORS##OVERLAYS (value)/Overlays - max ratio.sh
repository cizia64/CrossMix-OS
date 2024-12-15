#!/bin/sh
PATH="/mnt/SDCARD/System/bin:$PATH"
LD_LIBRARY_PATH="/mnt/SDCARD/System/lib:/usr/trimui/lib:$LD_LIBRARY_PATH"

[ "$1" != "-s" ] && /mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "Applying \"$(basename "$0" .sh)\" by default..."

# Directory containing .cfg files
cfg_dir="/mnt/SDCARD/RetroArch/.retroarch/config/"

# Directory to create new files
overlay_dir="/mnt/SDCARD/RetroArch/.retroarch/overlay/"

rm -rf /tmp/patches
mkdir /tmp/patches

# Initialize counters
cfg_count=0
skip_count=0
alt_count=0
notfound_count=0
found_count=0
# Recursively search for .cfg files in cfg_dir
while IFS= read -r -d '' cfg_file; do

	# If aspect_ratio_index exists, it's a special configuration, we skip to the next file (except if the ratio is 22 which is the default ratio "core provided")
	aspect_ratio_index=$(/mnt/SDCARD/System/usr/trimui/scripts/get_ra_cfg.sh "$cfg_file" "aspect_ratio_index")
	if [ "$aspect_ratio_index" = 22 ] || [ "$aspect_ratio_index" = 24 ]; then
		echo "Skipping file (special configuration): $cfg_file"
		skip_count=$((skip_count + 1))
	else

		# Extract the prefix of the file name (without the .cfg extension)
		prefix=$(basename "$cfg_file" .cfg)
		prefix=${prefix// /_}

		configPatchFile=$(mktemp -p /tmp/patches)

		if [ -e "${overlay_dir}${prefix}_max-ratio.png" ]; then
			echo "input_overlay = \"./.retroarch/overlay/${prefix}_max-ratio.cfg\"" >"$configPatchFile"
			echo "video_scale_integer = \"false\"" >>"$configPatchFile"
			echo "input_overlay_enable = \"true\"" >>"$configPatchFile"
			found_count=$((found_count + 1))
			echo "File created for $prefix: $configPatchFile"
		elif [ -e "${overlay_dir}${prefix}_pixel-perfect.png" ]; then # as fallback if the overlay with pixel-perfect exists then we take this one
			echo "input_overlay = \"./.retroarch/overlay/${prefix}_pixel-perfect.cfg\"" >"$configPatchFile"
			echo "video_scale_integer = \"true\"" >>"$configPatchFile"
			echo "input_overlay_enable = \"true\"" >>"$configPatchFile"
			alt_count=$((alt_count + 1))
			echo "Alternative pixel-perfect file created for $prefix: $configPatchFile"
		elif [ -e "${overlay_dir}${prefix}_custom.png" ]; then # as fallback if the overlay with _custom exists then we take this one
			echo "input_overlay = \"./.retroarch/overlay/${prefix}_custom.cfg\"" >"$configPatchFile"
			echo "video_scale_integer = \"true\"" >>"$configPatchFile"
			echo "input_overlay_enable = \"true\"" >>"$configPatchFile"
			alt_count=$((alt_count + 1))
			echo "Alternative custom file created for $prefix: $configPatchFile"
		else # no fallback available, we force the overlay even if it doesn't exist
			echo "input_overlay = \"./.retroarch/overlay/${prefix}_max-ratio.cfg\"" >"$configPatchFile"
			echo "video_scale_integer = \"false\"" >>"$configPatchFile"
			echo "input_overlay_enable = \"true\"" >>"$configPatchFile"
			notfound_count=$((notfound_count + 1))
			echo "No overlay image found for $prefix: $configPatchFile"
		fi

		echo "video_scale_integer_overscale = \"false\"" >>"$configPatchFile"
		echo "aspect_ratio_index = \"22\"" >>"$configPatchFile"
		sync

		/mnt/SDCARD/System/usr/trimui/scripts/patch_ra_cfg.sh "$configPatchFile" "$cfg_file" &

		# rm "$configPatchFile"
		sync
		found_count=$((found_count + 1))
	fi

	# Increment the count of .cfg files found
	cfg_count=$((cfg_count + 1))

	# Display a message for each created file
	# echo "Patch file created for $prefix: $configPatchFile"

done < <(find "$cfg_dir" -type f -name '*.cfg' ! -path "*VecX*" -print0)

script_name=$(basename "$0" .sh)

sync
# Display the total number of .cfg files found
echo -e "-----------------------------"
echo "Total number of .cfg files found: $cfg_count"
echo "   $found_count $script_name applied"
echo "   $alt_count replaced by pixel perfect"
echo "   $skip_count skipped (specific configugration)"
echo "   $notfound_count withtout png file at all"

# Menu modification to reflect the change immediately

json_file="/mnt/SDCARD/System/etc/crossmix.json"
if [ ! -f "$json_file" ]; then
	echo "{}" >"$json_file"
fi
/mnt/SDCARD/System/bin/jq --arg script_name "$script_name" '. += {"OVERLAYS": $script_name}' "$json_file" >"/tmp/json_file.tmp" && mv "/tmp/json_file.tmp" "$json_file"

/mnt/SDCARD/System/usr/trimui/scripts/mainui_state_update.sh "OVERLAYS" "$script_name"
