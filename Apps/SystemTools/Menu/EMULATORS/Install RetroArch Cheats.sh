#!/bin/sh
PATH="/mnt/SDCARD/System/bin:$PATH"
export LD_LIBRARY_PATH="/mnt/SDCARD/System/lib:$LD_LIBRARY_PATH"

button=$(/mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "Install RetroArch cheats ? Press A to continue, B to cancel." -k "A B")

if [ "$button" = "B" ]; then
    echo "Cancel Retroarch cheats extraction"
    /mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "Retroarch Cheats installation: Canceled." -t 0.5
    exit
fi

# Set CPU performance mode
echo performance >/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
echo 1416000 >/sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq

/mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "Installing Retroarch Cheats in background..." -t 3
source /mnt/SDCARD/System/usr/trimui/scripts/common_functions.sh
cp "/mnt/SDCARD/RetroArch/cheats.7z" "/tmp/cheats.7z"
extract_7z "/tmp/cheats.7z" "/mnt/SDCARD/RetroArch/.retroarch/cheats/" &
