#!/bin/sh
echo $0 $*
#!/bin/sh
echo $0 $*
source /mnt/SDCARD/System/usr/trimui/scripts/FolderOverrideFinder.sh
RA_DIR=/mnt/SDCARD/RetroArch
EMU_DIR=/mnt/SDCARD/Emus/N64
cd $RA_DIR/

$EMU_DIR/performance.sh

#disable netplay
NET_PARAM=


# Variable for the path to the Mupen64Plus directory
MUPEN_DIR="/mnt/SDCARD/RetroArch/.retroarch/config/Mupen64Plus GLES2"

# Extract the filename from the full path without the extension
ROM_PATH="$1"
ROM_NAME=$(basename "$ROM_PATH" | sed 's/\.[^.]*$//')

# Paths to the source files
N64_CFG="$MUPEN_DIR/N64.cfg"
N64_OPT="$MUPEN_DIR/Mupen64Plus GLES2.opt"

# Paths to the destination files
ROM_CFG="$MUPEN_DIR/$ROM_NAME.cfg"
ROM_OPT="$MUPEN_DIR/$ROM_NAME.opt"

# Create empty files if the source files do not exist
[ ! -f "$N64_CFG" ] && touch "$N64_CFG"
[ ! -f "$N64_OPT" ] && touch "$N64_OPT"

# Check if the destination files exist
if [ ! -f "$ROM_CFG" ] && [ ! -f "$ROM_OPT" ]; then
    # Copy the configuration files with the new name
    cp "$N64_CFG" "$N64_CFG"
    cp "$N64_OPT" "$ROM_OPT"
    echo "Copied $N64_CFG to $ROM_CFG"
    echo "Copied $N64_OPT to $ROM_OPT"
    
    # Apply the configuration patches
    /mnt/SDCARD/System/usr/trimui/scripts/patch_ra_cfg.sh "$MUPEN_DIR/widescreen.cfg" "$ROM_CFG"
    /mnt/SDCARD/System/usr/trimui/scripts/patch_ra_cfg.sh "$MUPEN_DIR/widescreen.opt" "$ROM_OPT"
    echo "Patch applied to $ROM_CFG"
    echo "Patch applied to $ROM_OPT"
	HOME=$RA_DIR/ $RA_DIR/ra64.trimui -v -L $RA_DIR/.retroarch/cores/mupen64plus_libretro.so "$@"
	# cleaning
	rm "$ROM_CFG"
	rm "$ROM_OPT"
else
    message="The following files already exist:"
    [ -f "$ROM_CFG" ] && message="$message $ROM_CFG"
    [ -f "$ROM_OPT" ] && message="$message $ROM_OPT"
    echo "$message"
fi





















