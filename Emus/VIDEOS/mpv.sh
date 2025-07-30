#!/bin/sh
PATH="/mnt/SDCARD/System/bin:$PATH"
export LD_LIBRARY_PATH=/lib:/lib64:/usr/lib:/mnt/SDCARD/System/lib/:/mnt/SDCARD/Apps/PortMaster/PortMaster:LD_LIBRARY_PATH

echo $0 $*
progdir=$(dirname "$0")
homedir=$(dirname "$1")
extension="${@##*.}"

cd "$progdir"

if [ "$extension" = "launch" ]; then
  sh "$1"
  exit
fi

if [ "$extension" = "m3u8" ]; then
  if [ -f "./streaming_manual.png" ]; then
    /mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -i "./streaming_manual.png"
  fi
fi

if [ "$extension" = "7z" ]; then
  /mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "Extracting..."
  /mnt/SDCARD/System/bin/7zz x -aoa "$1" -o/mnt/SDCARD/
  /mnt/SDCARD/System/usr/trimui/scripts/reset_list.sh "VIDEOS"
  sync
  exit
fi

/mnt/SDCARD/Apps/PortMaster/PortMaster/gptokeyb2 -1 "mpv" -c "keys.gptk" &
/mnt/SDCARD/System/bin/thd --triggers thd.conf /dev/input/event3 &

echo 1 >/tmp/stay_awake
HOME="$progdir" /mnt/SDCARD/System/bin/mpv "$@" --fullscreen --audio-buffer=1 --terminal=no # --lavfi-complex="[aid1]asplit[ao][a]; [a]showcqt[vo]" --script=/mnt/SDCARD/Emus/VIDEOS/.config/mpv/metadata_osd.lua  #--autofit=100%x1280    # for music: --geometry=720   # visu: --lavfi-complex="[aid1]asplit[ao][a]; [a]showcqt[vo]"  # --video-unscaled=no --panscan=1

rm /tmp/stay_awake

kill -9 $(pidof gptokeyb2)
kill -9 $(pidof thd)
