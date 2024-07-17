#!/bin/sh
echo $0 $*
source /mnt/SDCARD/System/usr/trimui/scripts/common_launcher.sh
RA_DIR=/mnt/SDCARD/RetroArch
EMU_DIR=/mnt/SDCARD/Emus/DC
cd $RA_DIR/

$EMU_DIR/cpufreq.sh
$EMU_DIR/effect.sh

#disable netplay
NET_PARAM=


# Variable for the path to the Flycast directory
FLYCAST_DIR="/mnt/SDCARD/RetroArch/.retroarch/config/Flycast"

# Extract the filename from the full path without the extension
ROM_PATH="$1"
ROM_NAME=$(basename "$ROM_PATH" | sed 's/\.[^.]*$//')

# Paths to the source files
DC_CFG="$FLYCAST_DIR/DC.cfg"
DC_OPT="$FLYCAST_DIR/DC.opt"

# Paths to the destination files
ROM_CFG="$FLYCAST_DIR/$ROM_NAME.cfg"
ROM_OPT="$FLYCAST_DIR/$ROM_NAME.opt"

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
    /mnt/SDCARD/System/usr/trimui/scripts/patch_ra_cfg.sh "$FLYCAST_DIR/widescreen.cfg" "$ROM_CFG"
    /mnt/SDCARD/System/usr/trimui/scripts/patch_ra_cfg.sh "$FLYCAST_DIR/widescreen.opt" "$ROM_OPT"
    echo "Patch applied to $ROM_CFG"
    echo "Patch applied to $ROM_OPT"
	HOME=$RA_DIR/ $RA_DIR/ra64.trimui -v -L $RA_DIR/.retroarch/cores/flycast_libretro.so "$@"
	# cleaning
	rm "$ROM_CFG"
	rm "$ROM_OPT"
else
    message="The following files already exist:"
    [ -f "$ROM_CFG" ] && message="$message $ROM_CFG"
    [ -f "$ROM_OPT" ] && message="$message $ROM_OPT"
    echo "$message"
fi





















