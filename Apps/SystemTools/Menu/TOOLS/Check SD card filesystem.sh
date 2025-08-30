#!/bin/sh
if ! pgrep "TermSP" >/dev/null; then
    /mnt/SDCARD/Apps/Terminal/launch_TermSP.sh -s 24 -e "$0"
    exit
fi

. /mnt/SDCARD/System/usr/trimui/scripts/update_common.sh
mkdir -p /mnt/SDCARD/System/logs/
UPDATE_LOG=/mnt/SDCARD/System/logs/sdcard_check.log

{
    echo ================================================================================
    date "+[%Y-%m-%d %H:%M:%S] Starting SD card check..."
    echo ================================================================================
} >> "$UPDATE_LOG"

check_filesystem --force | tee -a "$UPDATE_LOG"
echo -e "\nFull log available in $UPDATE_LOG"

echo -ne "${GREEN}SD Card Check finished.${NC}\n"
echo -ne "${YELLOW}"
read -n 1 -s -r -p "Press A to exit"
killall -9 "$0"
