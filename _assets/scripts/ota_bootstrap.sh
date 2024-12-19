#!/bin/sh
export PATH="/mnt/SDCARD/System/bin:/mnt/SDCARD/System/usr/trimui/scripts:$PATH"
export LD_LIBRARY_PATH="/mnt/SDCARD/System/lib:/usr/trimui/lib:$LD_LIBRARY_PATH"

CommonUpdateScript="/mnt/SDCARD/System/usr/trimui/scripts/update_common.sh"
currentUpdatePack=$("$CommonUpdateScript" -v)

GITHUB_REPOSITORY=cizia64/CrossMix-OS
UpdatePackUrl="https://raw.githubusercontent.com/$GITHUB_REPOSITORY/main/System/usr/trimui/scripts/update_common.sh"
wget --no-check-certificate --quiet --show-progress -O "/tmp/update_common.sh" "$UpdatePackUrl"
chmod +x "/tmp/update_common.sh"
onlineUpdatePack=$("/tmp/update_common.sh" -v)

if [ ! "$currentUpdatePack" = "$onlineUpdatePack" ]; then
    mv "/tmp/update_common.sh" "$CommonUpdateScript"
    sync
fi
source "$CommonUpdateScript"

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

if [ -f "/mnt/SDCARD/betatest" ]; then
    download_file "update_ota_release.sh - beta" "https://dl.dropbox.com/scl/fi/3omlfp6tb13hadh25ivod/update_ota_release.sh?rlkey=2if0wx1k4dta8ozzhevr1mfn9" -f "/mnt/SDCARD/System/usr/trimui/scripts/update_ota_release.sh"
else
    download_file "update_ota_release.sh" "https://raw.githubusercontent.com/cizia64/CrossMix-OS/refs/heads/main/System/usr/trimui/scripts/update_ota_release.sh" -d "/mnt/SDCARD/System/usr/trimui/scripts"
fi

if [ ! "$currentUpdatePack" = "$onlineUpdatePack" ] || [ "$missing_files" -eq 1 ]; then
    download_file "crossmix_update.sh" "https://raw.githubusercontent.com/$GITHUB_REPOSITORY/refs/heads/main/System/usr/trimui/scripts/crossmix_update.sh" -d "/mnt/SDCARD/System/usr/trimui/scripts"
    download_file "ota_update.sh" "https://raw.githubusercontent.com/$GITHUB_REPOSITORY/refs/heads/main/System/usr/trimui/scripts/ota_update.sh" -d "/mnt/SDCARD/System/usr/trimui/scripts"
    download_file "launch.sh" "https://raw.githubusercontent.com/$GITHUB_REPOSITORY/refs/heads/main/Apps/OTA-update/launch.sh" -f "/mnt/SDCARD/Apps/OTA-update/launch.sh"
    download_file "keys.gptk" "https://raw.githubusercontent.com/$GITHUB_REPOSITORY/refs/heads/main/Apps/OTA-update/keys.gptk" -f "/mnt/SDCARD/Apps/OTA-update/keys.gptk"
    download_file "Terminal launch.sh" "https://raw.githubusercontent.com/$GITHUB_REPOSITORY/refs/heads/main/Apps/Terminal/launch.sh" -f "/mnt/SDCARD/Apps/Terminal/launch.sh"
    download_file "shellect.sh" "https://raw.githubusercontent.com/$GITHUB_REPOSITORY/refs/heads/main/System/usr/trimui/scripts/shellect.sh" -d "/mnt/SDCARD/System/usr/trimui/scripts"
    sync
    /mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "Update scripts upgraded, please launch OTA update again." -t 5
    killall -2 SimpleTerminal
fi
