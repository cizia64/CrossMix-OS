#!/bin/sh
echo $0 $*
progdir=$(dirname "$0")
cd $progdir

launch_record() {
  sleep 3
  $bindir/ffmpeg \
    -f fbdev -framerate 30 -i /dev/fb0 \
    -f oss -i /dev/dsp \
    -vf "format=yuv420p" \
    -c:v libx264 -preset ultrafast -maxrate 8000k -bufsize 48000k -g 60 \
    -threads 3 \
    "output/$(date +%Y%m%d%H%M%S).mp4" &
  >/dev/null &
}

tkdir=/mnt/SDCARD/Apps/ScreencapTK
bindir=$tkdir/bin
libdir=$tkdir/lib
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/lib:/usr/trimui/lib/:$tkdir/lib
export PATH="$sysdir/bin:$PATH"
mkdir output

if pgrep "ffmpeg" >/dev/null; then
  killall -2 ffmpeg
  pkill -f "thd_ScreenRecorder.conf"
  aplay /mnt/SDCARD/Apps/ScreenRecorder/stopped.wav -d 1 &
  if ! [ "$1" = "-NoUI" ]; then
    /mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -i bg-exit.png -m "Record stopped." -k " "
  fi

else

  button=$(/mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "Press A to start recording, B to cancel. L1 + R1 to stop the recording." -k "A B" -fs 29)
  if [ "$button" = "B" ]; then
    /mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "Record canceled." -t 1
    exit
  else
    launch_record &
    sleep 1
    /mnt/SDCARD/System/bin/thd --triggers /mnt/SDCARD/Apps/ScreenRecorder/thd_ScreenRecorder.conf /dev/input/event* &
  fi
fi
