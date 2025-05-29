#!/bin/sh
export LD_LIBRARY_PATH=/lib:/usr/lib:./lib:/usr/lib64:/mnt/SDCARD/System/lib
export PATH="/mnt/SDCARD/System/bin:/mnt/SDCARD/System/usr/trimui/scripts:$PATH"

cpufreq.sh ondemand 2 6

RomPath=$(dirname "$1")
RomDir=$(basename "$RomPath")

if [ $RomDir = GZDoom ]; then

	IwadFile=$1
	IwadName="$(basename "$IwadFile" | sed 's/\.[^.]*$//')"

	echo "***************************************************************************"
	echo "IwadFile     $IwadFile"
	echo "RomPath      $RomPath"
	echo "RomDir       $RomDir"
	echo "***************************************************************************"

	MODS_DIR="/mnt/SDCARD/Roms/DOOM/GZDoom/mods"
	GZDOOM_DIR="/mnt/SDCARD/Emus/DOOM/GZDoom"
	cd "$GZDOOM_DIR"

	# We try to identify the current iwad, if not found in database it will probably not work with GZDoom
	md5_hash=$(md5sum "$1" | awk '{ print $1 }')
	echo "md5_hash: $md5_hash"

	version=$(jq -r --arg md5 "$md5_hash" 'to_entries | map(.value[] | select(.MD5Hash == $md5) | .Version) | .[0]' "$GZDOOM_DIR/iwad_checksums.json")

	if [ "$version" == "null" ] || [ -z "$version" ]; then
		echo "Error: No matching version found for the selected IWAD file."
		infoscreen.sh -i "$GZDOOM_DIR/bg_doom.png" -m "$(basename "$IwadFile") is an unknown iwad file. (menu+power to exit if frozen)" -t 2
		version="$IwadName (Unknown)"
	else
		echo "Iwad Version: $version"
	fi
	echo "***************************************************************************"

	# if additional mod files are present (wad,pk3,ipk3,pk7) , show a selector
	if [ "$(find "$MODS_DIR" -type f 2>/dev/null)" ]; then
		selector_output=$(selector -t "Choose a mod file to load, or press B to continue without a mod." -d "$MODS_DIR")
		selected_file="${selector_output#*: }"
		echo "Selected file: $selected_file"
	fi

	touch /var/trimui_inputd/swap_ab
	sync

	# Check if a file was selected or if "No file selected" was returned
	if ! [ -f "$selected_file" ]; then
		echo "No additional file selected or file not found. Launching gzdoom with only the iwad."
		infoscreen.sh -i "$GZDOOM_DIR/bg_doom.png" -m "$version"
		cd "$GZDOOM_DIR"
		HOME="$GZDOOM_DIR" ./gzdoom -iwad "$IwadFile"
	else
		infoscreen.sh -i "$GZDOOM_DIR/bg_doom.png" -m "$version + $(basename "$selected_file" | sed 's/\.[^.]*$//')"
		cd "$GZDOOM_DIR"
		HOME="$GZDOOM_DIR" ./gzdoom -iwad "$IwadFile" -file "$selected_file"
	fi

	rm /var/trimui_inputd/swap_ab
	sync
else
	source /mnt/SDCARD/System/usr/trimui/scripts/common_launcher.sh
	cd $RA_DIR/

	HOME=$RA_DIR/ $RA_DIR/ra64.trimui -v -L $RA_DIR/.retroarch/cores/prboom_libretro.so "$@"
fi
