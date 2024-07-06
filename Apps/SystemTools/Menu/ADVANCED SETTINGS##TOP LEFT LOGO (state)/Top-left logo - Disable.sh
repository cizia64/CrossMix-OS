#!/bin/sh
PATH="/mnt/SDCARD/System/bin:$PATH"
LD_LIBRARY_PATH="/mnt/SDCARD/System/lib:/usr/trimui/lib:$LD_LIBRARY_PATH"

/mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "Applying \"$(basename "$0" .sh)\" by default..."

CurrentTheme=$(/mnt/SDCARD/System/bin/jq -r .theme /mnt/UDISK/system.json)
cd "$CurrentTheme/skin/"

if [ ! -f ./nav-logo-off.png ]; then
    mv ./nav-logo.png ./nav-logo-off.png
    cp /mnt/SDCARD/System/usr/trimui/res/skin/empty.png ./nav-logo.png
else
    echo "The file ./nav-logo-off.png already exists."
fi

if [ ! -f ./icon-back-off.png ]; then
    mv ./icon-back.png ./icon-back-off.png
    cp /mnt/SDCARD/System/usr/trimui/res/skin/empty.png ./icon-back.png
else
    echo "The file ./nav-logo-off.png already exists."
fi

sync

# Menu modification to reflect the change immediately
/mnt/SDCARD/System/usr/trimui/scripts/mainui_state_update.sh "TOP LEFT LOGO" "disabled"