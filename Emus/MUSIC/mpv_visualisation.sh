#!/bin/sh
echo $0 $*
progdir=$(dirname "$0")
homedir=$(dirname "$1")

export LD_LIBRARY_PATH=/lib:/lib64:/usr/lib:/mnt/SDCARD/System/lib/

cd "$progdir"

/mnt/SDCARD/Apps/PortMaster/PortMaster/gptokeyb2 -1 "Music" -c "keys.gptk" &
sleep 1

echo 1 > /tmp/stay_awake
HOME="$progdir" /mnt/SDCARD/System/bin/mpv "$@" --fullscreen  --audio-buffer=1 --lavfi-complex="[aid1]asplit[ao][a]; [a]showcqt[vo]" #--script=/mnt/SDCARD/Emus/VIDEOS/.config/mpv/metadata_osd.lua  #--autofit=100%x1280    # for music: --geometry=720
rm /tmp/stay_awake

pkill -9 gptokeyb2
