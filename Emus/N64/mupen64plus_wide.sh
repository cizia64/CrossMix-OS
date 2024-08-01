#!/bin/sh
echo $0 $*

cd "$(dirname "$0")"

source /mnt/SDCARD/System/usr/trimui/scripts/common_launcher.sh
./performance.sh

cd /mnt/SDCARD/RetroArch

#disable netplay
NET_PARAM=

# Variable for the path to the Mupen64Plus directory
cd .retroarch/config/Mupen64Plus\ GLES2

# Extract the filename from the full path without the extension
ROM_NAME=$(basename "$1" | sed 's/\.[^.]*$//')

# Paths to the source files
N64_CFG="$PWD/N64.cfg"
N64_OPT="$PWD/Mupen64Plus GLES2.opt"

# Paths to the destination files
ROM_CFG="$PWD/$ROM_NAME.cfg"
ROM_OPT="$PWD/$ROM_NAME.opt"

# Create empty files if the source files do not exist
[ ! -f "$N64_CFG" ] && touch "$N64_CFG"
[ ! -f "$N64_OPT" ] && touch "$N64_OPT"

# Check if the destination files exist
if [ ! -f "$ROM_CFG" ] && [ ! -f "$ROM_OPT" ]; then
	# Copy the configuration files with the new name
	cp "$N64_CFG" "$ROM_CFG"
	cp "$N64_OPT" "$ROM_OPT"
	echo "Copied $N64_CFG to $ROM_CFG"
	echo "Copied $N64_OPT to $ROM_OPT"

	# Apply the configuration patches

	echo "/mnt/SDCARD/System/usr/trimui/scripts/patch_ra_cfg.sh $PWD/widescreen.cfg $ROM_CFG"
	/mnt/SDCARD/System/usr/trimui/scripts/patch_ra_cfg.sh "$PWD/widescreen.cfg" "$ROM_CFG"
	/mnt/SDCARD/System/usr/trimui/scripts/patch_ra_cfg.sh "$PWD/widescreen.opt" "$ROM_OPT"
	echo "Patch applied to $ROM_CFG"
	echo "Patch applied to $ROM_OPT"

	cd -

	HOME="$PWD" ./ra64.trimui -v $NET_PARAM -L .retroarch/cores/mupen64plus_libretro.so "$@"
	# cleaning
	rm "$ROM_CFG"
	rm "$ROM_OPT"
else
	message="The following files already exist:"
	[ -f "$ROM_CFG" ] && message="$message $ROM_CFG"
	[ -f "$ROM_OPT" ] && message="$message $ROM_OPT"
	echo "$message"
fi
