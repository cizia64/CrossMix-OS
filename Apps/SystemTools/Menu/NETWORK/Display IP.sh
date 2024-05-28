#!/bin/sh

IP=$(ip route get 1 2>/dev/null | awk '{print $NF;exit}')
echo "Current IP address: $IP"

/mnt/SDCARD/System/bin/sdl2imgshow \
  -i "/usr/trimui/res/skin/bg.png" \
  -f "/usr/trimui/res/regular.ttf" \
  -s 50 \
  -c "220,220,220" \
  -t "Current IP address: $IP" &

/mnt/SDCARD/System/usr/trimui/scripts/getkey.sh

pkill -f sdl2imgshow
