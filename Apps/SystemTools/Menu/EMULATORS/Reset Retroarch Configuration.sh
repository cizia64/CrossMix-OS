#!/bin/sh
LD_LIBRARY_PATH="/mnt/SDCARD/System/lib:/usr/trimui/lib:$LD_LIBRARY_PATH"
RA_DEFAULT_CONFIG="/mnt/SDCARD/RetroArch/default_config.7z"

button=$(/mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "Restore Retroarch: press A to continue, B to cancel." -k "A B")

if [ "$button" = "B" ]; then
  echo "Cancel Retroarch config restore"
  /mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "Restore Retroarch: Canceled." -t 0.5
  exit
fi

/mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "Restoring Retroarch configuration..."

/mnt/SDCARD/System/bin/7zz e $RA_DEFAULT_CONFIG -y -o/mnt/SDCARD/RetroArch retroarch.cfg
/mnt/SDCARD/System/bin/7zz x $RA_DEFAULT_CONFIG -y -o/mnt/SDCARD/RetroArch/.retroarch/config -x!retroarch.cfg 

sleep 0.1
