#!/bin/sh
export PATH="/mnt/SDCARD/System/bin:/mnt/SDCARD/System/usr/trimui/scripts:$PATH"
export LD_LIBRARY_PATH="/mnt/SDCARD/System/lib:/usr/trimui/lib:$LD_LIBRARY_PATH"

FILES_TO_CHECK="/mnt/SDCARD/System/usr/trimui/scripts/crossmix_update.sh
/mnt/SDCARD/System/usr/trimui/scripts/update_ota_release.sh
/mnt/SDCARD/System/usr/trimui/scripts/ota_update.sh
/mnt/SDCARD/Apps/OTA-update/launch.sh
/mnt/SDCARD/Apps/OTA-update/keys.gptk
/mnt/SDCARD/System/usr/trimui/scripts/shellect.sh
/mnt/SDCARD/System/usr/trimui/scripts/update_common.sh"

# Check if all required files exist
missing_files=0
for file in $FILES_TO_CHECK; do
    if [ ! -f "$file" ]; then
        missing_files=1
        break
    fi
done

BOOTSTRAP_VERSION=1.1
GITHUB_REPOSITORY=cizia64/CrossMix-OS
CommonUpdateScript="/mnt/SDCARD/System/usr/trimui/scripts/update_common.sh"

if [ "$missing_files" -eq 1 ]; then
    wget --no-check-certificate --quiet --show-progress -O "$CommonUpdateScript" "https://raw.githubusercontent.com/cizia64/CrossMix-OS/refs/heads/main/System/usr/trimui/scripts/update_common.sh"
    sync
    source "$CommonUpdateScript"

    download_file "crossmix_update.sh" "https://raw.githubusercontent.com/$GITHUB_REPOSITORY/refs/heads/main/System/usr/trimui/scripts/crossmix_update.sh" -d "/mnt/SDCARD/System/usr/trimui/scripts/"
    download_file "update_ota_release.sh" "https://raw.githubusercontent.com/$GITHUB_REPOSITORY/refs/heads/main/System/usr/trimui/scripts/update_ota_release.sh" -d "/mnt/SDCARD/System/usr/trimui/scripts/"
    download_file "ota_update.sh" "https://raw.githubusercontent.com/$GITHUB_REPOSITORY/refs/heads/main/System/usr/trimui/scripts/ota_update.sh" -d "/mnt/SDCARD/System/usr/trimui/scripts/"
    download_file "launch.sh" "https://raw.githubusercontent.com/$GITHUB_REPOSITORY/refs/heads/main/Apps/OTA-update/launch.sh" -f "/mnt/SDCARD/Apps/OTA-update/launch.sh"
    download_file "keys.gptk" "https://raw.githubusercontent.com/$GITHUB_REPOSITORY/refs/heads/main/Apps/OTA-update/keys.gptk" -f "/mnt/SDCARD/Apps/OTA-update/keys.gptk"
    download_file "shellect.sh" "https://raw.githubusercontent.com/$GITHUB_REPOSITORY/refs/heads/main/System/usr/trimui/scripts/shellect.sh" -d "/mnt/SDCARD/System/usr/trimui/scripts/"
    download_file "update_common.sh" "https://raw.githubusercontent.com/$GITHUB_REPOSITORY/refs/heads/main/System/usr/trimui/scripts/update_common.sh" -d "/mnt/SDCARD/System/usr/trimui/scripts/"
    sync
    /mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "Update scripts upgraded, please launch OTA update again." -t 5
    killall -2 SimpleTerminal
fi
