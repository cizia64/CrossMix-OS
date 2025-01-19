#!/bin/sh

PATH="/mnt/SDCARD/System/bin:$PATH"
LD_LIBRARY_PATH="/mnt/SDCARD/System/lib:/usr/trimui/lib:$LD_LIBRARY_PATH"
script_name="$(basename "$0" .sh)"
if [ "$script_name" = "overlays_switcher" ]; then
    script_name=$(jq -r '.["OVERLAYS"]' "/mnt/SDCARD/System/etc/crossmix.json")
else
    /mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "Applying \"$(basename "$0" .sh)\" by default..."
fi

ratio=$(echo "${script_name#*- }" | tr ' ' '-')
display="$(/usr/sbin/fbset | grep ^mode | cut -d "\"" -f 2 | cut -d "-" -f 1)"
if [ "${script_name% -*}" = "Overlays" ]; then
    # Directory to create new files
    overlay_dir="/mnt/SDCARD/RetroArch/.retroarch/overlay/$display"
    if [ "$ratio" = "max-ratio" ]; then
        alt_ratio="pixel-perfect"
    else
        alt_ratio="max-ratio"
    fi
fi

# Directory containing .cfg files
cfg_dir="/mnt/SDCARD/RetroArch/.retroarch/config/"

cfg_count=0
skip_count=0
alt_count=0
found_count=0
notfound_count=0

rm -rf /tmp/patches
mkdir /tmp/patches


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
        used_ratio=$ratio
        if [ -z "$overlay_dir" ]; then
            echo 'input_overlay_enable = "false"' >"$configPatchFile"
        else
            if [ -e "$overlay_dir/${prefix}_$ratio.png" ]; then
                echo "input_overlay = \"$overlay_dir/${prefix}_$ratio.cfg\"" >"$configPatchFile"
                found_count=$((found_count + 1))
                echo "File created for $prefix: $configPatchFile"
            elif [ -e "$overlay_dir/${prefix}_$alt_ratio.png" ]; then # as fallback if the overlay with pixel-perfect exists then we take this one
                echo "input_overlay = \"$overlay_dir/${prefix}_$alt_ratio.cfg\"" >"$configPatchFile"
                used_ratio=$alt_ratio
                alt_count=$((alt_count + 1))
                echo "Alternative pixel-perfect file created for $prefix: $configPatchFile"
            elif [ -e "$overlay_dir/${prefix}_custom.png" ]; then # as fallback if the overlay with _custom exists then we take this one
                echo "input_overlay = \"$overlay_dir/${prefix}_custom.cfg\"" >"$configPatchFile"
                used_ratio=pixel-perfect
                alt_count=$((alt_count + 1))
                echo "Alternative custom file created for $prefix: $configPatchFile"
            else # no fallback available, we force the overlay even if it doesn't exist
                echo "input_overlay = \"$overlay_dir/${prefix}_$ratio.cfg\"" >"$configPatchFile"
                notfound_count=$((notfound_count + 1))
                echo "No overlay image found for $prefix: $configPatchFile"
            fi
            echo 'input_overlay_enable = "true"' >>"$configPatchFile"
        fi
        if [ "$used_ratio" = "pixel-perfect" ]; then
            echo 'video_scale_integer = "true"' >>"$configPatchFile"
        else
            echo 'video_scale_integer = "false"' >>"$configPatchFile"
        fi
        echo 'video_scale_integer_overscale = "false"' >>"$configPatchFile"
        if [ "$used_ratio" = "fullscreen" ]; then
            echo 'aspect_ratio_index = "24"' >>"$configPatchFile"
        else
            echo 'aspect_ratio_index = "22"' >>"$configPatchFile"
        fi


        /mnt/SDCARD/System/usr/trimui/scripts/patch_ra_cfg.sh "$configPatchFile" "$cfg_file" &
        found_count=$((found_count + 1))

    fi
    # Increment the count of .cfg files found
    cfg_count=$((cfg_count + 1))

	# Display a message for each created file
	# echo "Patch file created for $prefix: $configPatchFile"

done < <(find "$cfg_dir" -type f -name '*.cfg' ! -path "*VecX*" -print0)
while pgrep patch_ra_cfg.sh; do
    sleep 1
done
sync

# Display the total number of .cfg files found
echo -e "-----------------------------"
echo "Total number of .cfg files found: $cfg_count"
echo "   $found_count $script_name applied"
# echo "   $alt_count replaced by pixel perfect"
echo "   $skip_count skipped (specific configugration)"
# echo "   $notfound_count withtout png file at all"

# Menu modification to reflect the change immediately

json_file="/mnt/SDCARD/System/etc/crossmix.json"
if [ ! -f "$json_file" ]; then
	echo "{}" >"$json_file"
fi
/mnt/SDCARD/System/bin/jq --arg script_name "$script_name" '. += {"OVERLAYS": $script_name}' "$json_file" >"/tmp/json_file.tmp" && mv "/tmp/json_file.tmp" "$json_file"

/mnt/SDCARD/System/usr/trimui/scripts/mainui_state_update.sh "OVERLAYS" "$script_name"
