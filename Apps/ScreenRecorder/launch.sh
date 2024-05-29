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
  
  /mnt/SDCARD/System/bin/sdl2imgshow \
    -i "/mnt/SDCARD/trimui/res/crossmix-os/bg-exit.png" \
    -f "/mnt/SDCARD/System/resources/DejaVuSans.ttf" \
    -s 30 \
    -c "220,220,220" \
    -t "Record stopped." &
	
  /mnt/SDCARD/System/usr/trimui/scripts/getkey.sh
  pkill -f sdl2imgshow
else

  /mnt/SDCARD/System/bin/sdl2imgshow \
    -i "/mnt/SDCARD/trimui/res/crossmix-os/bg-exit.png" \
    -f "/mnt/SDCARD/System/resources/DejaVuSans.ttf" \
    -s 30 \
    -c "220,220,220" \
    -t "Press any key to start recording now. Launch the app again to stop the recording." &
	
  /mnt/SDCARD/System/usr/trimui/scripts/getkey.sh
  pkill -f sdl2imgshow

  launch_record &

fi
