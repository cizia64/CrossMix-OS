#!/bin/sh
BOOTSTRAP_VERSION=1.0
GITHUB_REPOSITORY=cizia64/CrossMix-OS
version=$(cat /mnt/SDCARD/System/usr/trimui/crossmix-version.txt)

url="https://raw.githubusercontent.com/$GITHUB_REPOSITORY/main/_assets/patchs/CrossMix-OS_v$version.sh"

if /mnt/SDCARD/System/bin/wget -q --spider "$url"; then

    button=$(/mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "Patch for CrossMix-OS_v$version found. Press A to apply, B to cancel." -k "A B")
    if [ "$button" = "A" ]; then
        curl -k -s "$url" | sh
    fi

else

    /mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "No new version, come back later ;)" -t 1

fi
killall -2 SimpleTerminal
