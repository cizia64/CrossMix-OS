#!/bin/sh
progdir=$(dirname "$0")
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/lib:/usr/trimui/lib:/mnt/SDCARD/System/lib

cd "$progdir"

if [ "$1" = "-NoUI" ]; then
  pkill -f /mnt/SDCARD/System/bin/mpv
  pkill -f "mpv_thd.conf"
else
  pkill -f /mnt/SDCARD/System/bin/mpv
  pkill -f "mpv_thd.conf"
  HOME="$progdir" /mnt/SDCARD/System/bin/mpv "$@" --no-video --audio-buffer=1 --cache=no --terminal=no &
  /mnt/SDCARD/System/bin/thd --triggers /mnt/SDCARD/Emus/MUSIC/mpv_thd.conf /dev/input/event3 &
  # button=$(/mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "Press L1 + R1 to stop the background play." -fs 29 -t 0)
fi
