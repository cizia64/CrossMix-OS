#!/bin/sh
source /mnt/SDCARD/System/usr/trimui/scripts/launchers/common_launcher.sh
cpufreq.sh ondemand 5 7

cd "$RA_DIR"

if ! find "/mnt/SDCARD/BIOS" -maxdepth 1 -iname "scph*" -o -iname "psxonpsp660.bin" -o -iname "ps*.bin" | grep -q .; then
	infoscreen.sh -i bg-exit.png -m "No bios found, SwanStation will probably not work." -k " "
fi

#disable netplay
NET_PARAM=

cd $PWD/.retroarch/config/SwanStation

# Extract the filename from the full path without the extension
ROM_PATH="$1"
ROM_NAME=$(basename "$ROM_PATH" | sed 's/\.[^.]*$//')

# Paths to the source files
PS_CFG="$PWD/PS.cfg"
PS_OPT="$PWD/PS.opt"

# Paths to the destination files
ROM_CFG="$PWD/$ROM_NAME.cfg"
ROM_OPT="$PWD/$ROM_NAME.opt"

# Create empty files if the source files do not exist
[ ! -f "$PS_CFG" ] && touch "$PS_CFG"
[ ! -f "$PS_OPT" ] && touch "$PS_OPT"

# Check if the destination files exist
if [ ! -f "$ROM_CFG" ] && [ ! -f "$ROM_OPT" ]; then
	# Copy the configuration files with the new name
	cp "$PS_CFG" "$ROM_CFG"
	cp "$PS_OPT" "$ROM_OPT"
	echo "Copied $PS_CFG to $ROM_CFG"
	echo "Copied $PS_OPT to $ROM_OPT"

	# Apply the configuration patches
	patch_ra_cfg.sh "$PWD/widescreen.cfg" "$ROM_CFG"
	patch_ra_cfg.sh "$PWD/widescreen.opt" "$ROM_OPT"
	echo "Patch applied to $ROM_CFG"
	echo "Patch applied to $ROM_OPT"

	cd -
	HOME="$PWD" ./ra64.trimui -v $NET_PARAM -L .retroarch/cores/swanstation_libretro.so "$@"

	# cleaning
	rm "$ROM_CFG"
	rm "$ROM_OPT"
else
	message="The following files already exist:"
	[ -f "$ROM_CFG" ] && message="$message $ROM_CFG"
	[ -f "$ROM_OPT" ] && message="$message $ROM_OPT"
	echo "$message"
fi
