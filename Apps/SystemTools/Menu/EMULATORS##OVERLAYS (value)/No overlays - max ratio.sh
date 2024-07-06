#!/bin/sh
PATH="/mnt/SDCARD/System/bin:$PATH"
LD_LIBRARY_PATH="/mnt/SDCARD/System/lib:/usr/trimui/lib:$LD_LIBRARY_PATH"


/mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "Applying \"$(basename "$0" .sh)\" by default..."

# Directory containing .cfg files
cfg_dir="/mnt/SDCARD/RetroArch/.retroarch/config/"

# Directory to create new files
overlay_dir="/mnt/SDCARD/RetroArch/.retroarch/overlay/"

# Initialize counters
cfg_count=0
skip_count=0
alt_count=0
notfound_count=0
found_count=0
# Recursively search for .cfg files in cfg_dir
while IFS= read -r -d '' cfg_file; do

	# If aspect_ratio_index exists, it's a special configuration, we skip to the next file (except if the ratio is 22 which is the default ratio "core provided")
	if grep -q "aspect_ratio_index" "$cfg_file" && ! grep -qE "aspect_ratio_index = \"(22|24)\"" "$cfg_file"; then
		echo "Skipping file (special configuration): $cfg_file"
		skip_count=$((skip_count + 1))
	else

		# Extract the prefix of the file name (without the .cfg extension)
		prefix=$(basename "$cfg_file" .cfg)
		prefix=${prefix// /_}

		configPatchFile="${cfg_file}_patch"
		# Path to the _max-ratio.cfg and _pixel-perfect.cfg files
		max_ratio_file="${overlay_dir}${prefix}_max-ratio.cfg"
		pixel_perfect_file="${overlay_dir}${prefix}_pixel-perfect.cfg"

		# Check if _max-ratio.cfg file already exists

		# Add configurations to _max-ratio.cfg

		echo "input_overlay_enable = \"false\"" >>"$configPatchFile"
		echo "video_scale_integer = \"false\"" >>"$configPatchFile"
		echo "video_scale_integer_overscale = \"false\"" >>"$configPatchFile"
		echo "aspect_ratio_index = \"22\"" >>"$configPatchFile"
		sync

		/mnt/SDCARD/System/usr/trimui/scripts/patch_ra_cfg.sh "$configPatchFile" "$cfg_file"

		rm "$configPatchFile"
		sync
	fi

	# Increment the count of .cfg files found
	cfg_count=$((cfg_count + 1))

	# Display a message for each created file
	echo "Files created for $prefix: $configPatchFile"

done < <(find "$cfg_dir" -type f -name '*.cfg' ! -path "*VecX*" -print0)

sync
# Display the total number of .cfg files found
echo -e "-----------------------------"
echo "Total number of .cfg files found: $cfg_count"
echo "   $found_count max ratio overlays applied"
echo "   $alt_count replaced by pixel perfect"
echo "   $skip_count skipped (specific configugration)"
echo "   $notfound_count withtout png file at all"

# Menu modification to reflect the change immediately

script_name=$(basename "$0" .sh)

json_file="/mnt/SDCARD/System/etc/crossmix.json"
if [ ! -f "$json_file" ]; then
  echo "{}" >"$json_file"
fi
/mnt/SDCARD/System/bin/jq --arg script_name "$script_name" '. += {"OVERLAYS": $script_name}' "$json_file" >"/tmp/json_file.tmp" && mv "/tmp/json_file.tmp" "$json_file"

/mnt/SDCARD/System/usr/trimui/scripts/mainui_state_update.sh "OVERLAYS" "$script_name"