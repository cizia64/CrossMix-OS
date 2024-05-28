#!/bin/sh
LD_LIBRARY_PATH="/mnt/SDCARD/System/lib:/usr/trimui/lib:$LD_LIBRARY_PATH"

/mnt/SDCARD/System/bin/sdl2imgshow \
  -i "/usr/trimui/res/skin/bg.png" \
  -f "/mnt/SDCARD/System/resources/DejaVuSans.ttf" \
  -s 25 \
  -c "220,220,220" \
  -t "Restore Retroarch: press A to continue, B to cancel." &
sleep 1
pkill -f sdl2imgshow

button=$("/mnt/SDCARD/System/usr/trimui/scripts/getkey.sh" B A)

if [ "$button" = "B" ]; then
  echo "Cancel Retroarch config restore"
  /mnt/SDCARD/System/bin/sdl2imgshow \
    -i "/usr/trimui/res/skin/bg.png" \
    -f "/mnt/SDCARD/System/resources/DejaVuSans.ttf" \
    -s 25 \
    -c "220,220,220" \
    -t "Restore Retroarch: Canceled." &
  sleep 0.5
  pkill -f sdl2imgshow
  exit
fi

/mnt/SDCARD/System/bin/sdl2imgshow \
  -i "/usr/trimui/res/skin/bg.png" \
  -f "/mnt/SDCARD/System/resources/DejaVuSans.ttf" \
  -s 50 \
  -c "220,220,220" \
  -t "Restoring Retroarch configuration..." &

unzip -o /mnt/SDCARD/RetroArch/default_config.7z -d /mnt/SDCARD/

sleep 0.1
pkill -f sdl2imgshow
