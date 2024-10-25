#!/bin/sh
source /mnt/SDCARD/System/usr/trimui/scripts/common_launcher.sh
cpufreq.sh ondemand 5 7

cd $RA_DIR/

if ! find "/mnt/SDCARD/BIOS" -maxdepth 1 -iname "scph*" -o -iname "psxonpsp660.bin" -o -iname "ps*.bin" | grep -q .; then
    /mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -i bg-exit.png -m "No bios found, SwanStation will probably not work." -k " "
fi

# Variable for the path to the SwanStation directory
SWANSTATION_DIR="/mnt/SDCARD/RetroArch/.retroarch/config/SwanStation"

# Extract the filename from the full path without the extension
ROM_PATH="$1"
ROM_NAME=$(basename "$ROM_PATH" | sed 's/\.[^.]*$//')

# Paths to the source files
PS_CFG="$SWANSTATION_DIR/PS.cfg"
PS_OPT="$SWANSTATION_DIR/PS.opt"

# Paths to the destination files
ROM_CFG="$SWANSTATION_DIR/$ROM_NAME.cfg"
ROM_OPT="$SWANSTATION_DIR/$ROM_NAME.opt"

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
    /mnt/SDCARD/System/usr/trimui/scripts/patch_ra_cfg.sh "$SWANSTATION_DIR/widescreen.cfg" "$ROM_CFG"
    /mnt/SDCARD/System/usr/trimui/scripts/patch_ra_cfg.sh "$SWANSTATION_DIR/widescreen.opt" "$ROM_OPT"
    echo "Patch applied to $ROM_CFG"
    echo "Patch applied to $ROM_OPT"
    HOME=$RA_DIR/ $RA_DIR/ra64.trimui -v -L $RA_DIR/.retroarch/cores/swanstation_libretro.so "$@"

    # cleaning
    rm "$ROM_CFG"
    rm "$ROM_OPT"
else
    message="The following files already exist:"
    [ -f "$ROM_CFG" ] && message="$message $ROM_CFG"
    [ -f "$ROM_OPT" ] && message="$message $ROM_OPT"
    echo "$message"
fi
