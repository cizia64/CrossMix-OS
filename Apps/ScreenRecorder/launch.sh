#!/bin/sh
echo "========================================="
echo $0 $*

tkdir=/mnt/SDCARD/Apps/ScreencapTK
bindir=$tkdir/bin
outdir=/mnt/SDCARD/Apps/ScreenRecorder/output
export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/usr/lib:/usr/trimui/lib/:$tkdir/lib"

launch_record() {
  mkdir -p $outdir
  sleep 1
  $bindir/ffmpeg \
    -f fbdev -framerate 30 -i /dev/fb0 \
    -f oss -i /dev/dsp \
    -vf "format=yuv420p" \
    -c:v libx264 -preset ultrafast -maxrate 8000k -bufsize 48000k -g 60 \
    -threads 3 \
    "$outdir/$(date +%Y%m%d%H%M%S).mp4" &
  /mnt/SDCARD/System/bin/thd --triggers /mnt/SDCARD/Apps/ScreenRecorder/thd_ScreenRecorder.conf /dev/input/event* &
}

if [ "$1" = "--stop" ]; then
  killall -2 ffmpeg
  pkill -f "thd_ScreenRecorder.conf"
  aplay /mnt/SDCARD/Apps/ScreenRecorder/stopped.wav -d 1
  if [ "$(jq -r '.vol' /mnt/UDISK/system.json)" -lt 6 ] ; then
    /mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -i bg-exit.png -m "Record stopped." -k " "
  fi

else
  button=$(/mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "Press A to start recording, B to cancel. L1 + R1 to stop the recording." -k "A B" -fs 29)
  if [ "$button" = "B" ]; then
    /mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "Record canceled." -t 1
    exit
  else
    launch_record
  fi
fi
