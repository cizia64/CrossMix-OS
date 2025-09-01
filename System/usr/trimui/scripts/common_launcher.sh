#!/bin/sh
export PATH="/mnt/SDCARD/System/usr/trimui/scripts/:/mnt/SDCARD/System/bin:$PM_DIR:${PATH:+:$PATH}"
export LD_LIBRARY_PATH="/usr/trimui/lib:/mnt/SDCARD/System/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

# ANSI colors
RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
CYAN="\033[1;36m"
RESET="\033[0m"

# Pretty print section header
print_blue() {
    printf "${BLUE}%s${RESET}\n" "$1"
}

# Pretty print key=value
print_var() {
    printf "${GREEN}%-20s${RESET}: %s\n" "$1" "$2"
}

print_blue "$0 $*"
PM_DIR="/mnt/SDCARD/Apps/PortMaster/PortMaster"

# Input variables
ROM_REAL_PATH=$(realpath "$1")
EMU_DIR="$(echo "$0" | sed -E 's|(.*Emus/[^/]+)/.*|\1|')"
if [ "${1#"/tmp/folderspoof/"}" != "$1" ]; then
    ROM_DIR=$(dirname "$1")
else
    ROM_DIR=$(echo "$1" | sed -E 's|(.*Roms/[^/]+)/.*|\1|')
fi


ROM_FILENAME=$(basename "$1")
ROM_FILENAME_NOEXT=${ROM_FILENAME%.*}

printf "\n"
print_blue "=== ROM Information ==="
print_var "ROM_REAL_PATH" "$ROM_REAL_PATH"
print_var "ROM_DIR" "$ROM_DIR"
print_var "ROM_FILENAME" "$ROM_FILENAME"
print_var "ROM_FILENAME_NOEXT" "$ROM_FILENAME_NOEXT"
print_var "EMU_DIR" "$EMU_DIR"
print_blue "======================="


/mnt/SDCARD/System/usr/trimui/scripts/button_state.sh Y
if [ $? -eq 10 ]; then
    source /mnt/SDCARD/System/usr/trimui/scripts/romscripts/.romscript_launcher.sh
    exit
fi

dir=/mnt/SDCARD/System/usr/trimui/scripts
source $dir/save_launcher.sh

if [ -z "$2" ]; then
    /mnt/SDCARD/System/bin/activities time "$1" $$ &
fi

if grep -q ra64.trimui "$0"; then
    RA_DIR="/mnt/SDCARD/RetroArch"
    export PATH=$PATH:$RA_DIR
    source $dir/FolderOverrideFinder.sh
    ra_audio_switcher.sh
    touch /var/trimui_inputd/ra_hotkey
fi

cd "$EMU_DIR"
