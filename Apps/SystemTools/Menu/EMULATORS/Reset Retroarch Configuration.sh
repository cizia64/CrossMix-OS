#!/bin/sh
LD_LIBRARY_PATH="/mnt/SDCARD/System/lib:/usr/trimui/lib:$LD_LIBRARY_PATH"

button=$(/mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "Restore Retroarch: press A to continue, B to cancel." -k "A B")

if [ "$button" = "B" ]; then
  echo "Cancel Retroarch config restore"
  /mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "Restore Retroarch: Canceled." -t 0.5
  exit
fi

/mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "Restoring Retroarch configuration..."

/mnt/SDCARD/System/bin/7zz x -aoa /mnt/SDCARD/RetroArch/default_config.7z -o/mnt/SDCARD/

sleep 0.1
