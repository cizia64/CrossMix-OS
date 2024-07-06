#!/bin/sh

theme=$(basename "$0" .sh)
[ "$theme" = "Default" ] && theme="CrossMix - OS"

if [ -d "/mnt/SDCARD/Themes/${theme}" ]; then
    /mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "Applying \"${theme}\" theme."
    /usr/trimui/bin/systemval "theme" "/mnt/SDCARD/Themes/${theme}/"
else
    echo "Theme directory Themes/${theme} does not exist."
    /mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "\"${theme}\" theme directory does not exist !!" -c red -t 3
fi

/mnt/SDCARD/System/usr/trimui/scripts/mainui_state_update.sh "THEMES" "$theme"
