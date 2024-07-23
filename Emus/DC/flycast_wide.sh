#!/bin/sh
source /mnt/SDCARD/System/usr/trimui/scripts/launchers/common_launcher.sh
cpufreq.sh performance 7 7

./effect.sh

#disable netplay
NET_PARAM=

cd "$RA_DIR"

cd ".retroarch/config/Flycast"

# Extract the filename from the full path without the extension
ROM_NAME=$(basename "$1" | sed 's/\.[^.]*$//')

# Paths to the source files
DC_CFG="$PWD/DC.cfg"
DC_OPT="$PWD/DC.opt"

# Paths to the destination files
ROM_CFG="$PWD/$ROM_NAME.cfg"
ROM_OPT="$PWD/$ROM_NAME.opt"

# Create empty files if the source files do not exist
[ ! -f "$DC_CFG" ] && touch "$DC_CFG"
[ ! -f "$DC_OPT" ] && touch "$DC_OPT"

# Check if the destination files exist
if [ ! -f "$ROM_CFG" ] && [ ! -f "$ROM_OPT" ]; then
	# Copy the configuration files with the new name
	cp "$DC_CFG" "$ROM_CFG"
	cp "$DC_OPT" "$ROM_OPT"
	echo "Copied $DC_CFG to $ROM_CFG"
	echo "Copied $DC_OPT to $ROM_OPT"

	# Apply the configuration patches
	/mnt/SDCARD/System/usr/trimui/scripts/patch_ra_cfg.sh "$PWD/widescreen.cfg" "$ROM_CFG"
	/mnt/SDCARD/System/usr/trimui/scripts/patch_ra_cfg.sh "$PWD/widescreen.opt" "$ROM_OPT"
	echo "Patch applied to $ROM_CFG"
	echo "Patch applied to $ROM_OPT"

	cd -
	HOME="$PWD" ./ra64.trimui -v $NET_PARAM -L .retroarch/cores/flycast_libretro.so "$@"
	# cleaning
	rm "$ROM_CFG"
	rm "$ROM_OPT"
else
	message="The following files already exist:"
	[ -f "$ROM_CFG" ] && message="$message $ROM_CFG"
	[ -f "$ROM_OPT" ] && message="$message $ROM_OPT"
	echo "$message"
fi
