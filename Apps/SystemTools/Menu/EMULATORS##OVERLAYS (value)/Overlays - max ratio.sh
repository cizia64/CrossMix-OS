#!/bin/sh
PATH="/mnt/SDCARD/System/bin:$PATH"
LD_LIBRARY_PATH="/mnt/SDCARD/System/lib:/usr/trimui/lib:$LD_LIBRARY_PATH"


/mnt/SDCARD/System/bin/sdl2imgshow \
	-i "/mnt/SDCARD/trimui/res/crossmix-os/bg-info.png" \
	-f "/mnt/SDCARD/System/resources/DejaVuSans.ttf" \
	-s 50 \
	-c "220,220,220" \
	-t "Applying \"$(basename "$0" .sh)\" by default..." &

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

		/mnt/SDCARD/System/usr/trimui/scripts/patch_ra_cfg.sh "$configPatchFile" "$cfg_file"

		rm "$configPatchFile"
		sync
	fi

	# Increment the count of .cfg files found
	cfg_count=$((cfg_count + 1))

	# Display a message for each created file
	

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

database_file="/mnt/SDCARD/Apps/SystemTools/Menu/Menu_cache7.db"

sqlite3 "$database_file" "UPDATE Menu_roms SET disp = 'OVERLAYS ($script_name)',pinyin = 'OVERLAYS ($script_name)',cpinyin = 'OVERLAYS ($script_name)',opinyin = 'OVERLAYS ($script_name)' WHERE disp LIKE 'OVERLAYS (%)';"
sqlite3 "$database_file" "UPDATE Menu_roms SET ppath = 'OVERLAYS ($script_name)' WHERE ppath LIKE 'OVERLAYS (%)';"
json_file="/tmp/state.json"

jq --arg script_name "$script_name" '.list |= map(if (.ppath | index("OVERLAYS ")) then .ppath = "OVERLAYS (\($script_name))" else . end)' "$json_file" >"$json_file.tmp" && mv "$json_file.tmp" "$json_file"

sync
sleep 0.1
pkill -f sdl2imgshow
