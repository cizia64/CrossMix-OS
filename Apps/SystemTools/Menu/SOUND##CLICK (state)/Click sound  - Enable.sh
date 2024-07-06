#!/bin/sh
PATH="/mnt/SDCARD/System/bin:$PATH"
LD_LIBRARY_PATH="/mnt/SDCARD/System/lib:/usr/trimui/lib:$LD_LIBRARY_PATH"

/mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "Applying \"$(basename "$0" .sh)\" on current theme."

CurrentTheme=$(/mnt/SDCARD/System/bin/jq -r .theme /mnt/UDISK/system.json)
cd "$CurrentTheme/sound/"
mv ./click-off.wav ./click.wav

# we modify the DB entries to reflect the current state
/mnt/SDCARD/System/usr/trimui/scripts/mainui_state_update.sh "CLICK" "enabled"
