#!/bin/sh
echo "========================================="
echo $0 $*

tkdir=/mnt/SDCARD/Apps/ScreencapTK
bindir=$tkdir/bin
outdir=/mnt/SDCARD/Videos/ScreenRecorder/
export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/usr/lib:/usr/trimui/lib/:$tkdir/lib"

launch_record() {
  /mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "Starting recording..."
  mkdir -p "$outdir"
  sleep 1.5
  $bindir/ffmpeg \
    -f fbdev -framerate 30 -i /dev/fb0 \
    -f oss -i /dev/dsp \
    -vf "format=yuv420p" \
    -c:v libx264 -preset ultrafast -maxrate 8000k -bufsize 48000k -g 60 \
    -threads 3 \
    "$outdir/$(date +%F_%H-%M-%S).mp4" &
  ffmpeg_pid=$!

  sleep 1
  if kill -0 "$ffmpeg_pid" 2>/dev/null; then
    /mnt/SDCARD/System/bin/thd --triggers /mnt/SDCARD/Apps/ScreenRecorder/thd_ScreenRecorder.conf /dev/input/event* &
  else
    sleep 1
    /usr/trimui/osd/show_warning_msg.sh "Failed to start recording."
  fi
}

stop_record() {
  killall -2 ffmpeg 2>/dev/null
  pkill -f "thd_ScreenRecorder.conf"
  aplay /mnt/SDCARD/Apps/ScreenRecorder/stopped.wav -d 1
  /usr/trimui/osd/show_info_msg.sh "Record stopped."
  if [ "$(jq -r '.vol' /mnt/UDISK/system.json)" -lt 6 ]; then
    /mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -i bg-exit.png -m "Record stopped." -k " "
  fi
}

if [ "$1" = "--stop" ]; then
  stop_record
else
  if pgrep ffmpeg >/dev/null; then
    button=$(/mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "A recording is already in progress. Press A to stop it and start a new one, B to quit." -k "A B" -fs 29)
    if [ "$button" = "A" ]; then
      stop_record
      launch_record
    else
      /mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "Record still running, press L1 + R1 to stop the recording." -t 1
      exit
    fi
  else
    button=$(/mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "Press A to start recording, B to cancel. L1 + R1 to stop the recording." -k "A B" -fs 29)
    if [ "$button" = "B" ]; then
      /mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "Record canceled."
      exit
    else
      launch_record &
    fi
  fi
fi
