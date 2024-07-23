#!/bin/sh
source /mnt/SDCARD/System/usr/trimui/scripts/launchers/common_launcher.sh

/mnt/SDCARD/Apps/PortMaster/PortMaster/gptokeyb2 -1 "mpv" -c "keys.gptk" &
sleep 0.4

echo 1 > /tmp/stay_awake
HOME="$PWD" /mnt/SDCARD/System/bin/mpv "$@" --fullscreen --audio-buffer=1 --cache=no --terminal=no --lavfi-complex="[aid1]asplit[ao][a]; [a]showcqt[vo]" #--script=/mnt/SDCARD/Emus/VIDEOS/.config/mpv/metadata_osd.lua  #--autofit=100%x1280    # for music: --geometry=720
rm /tmp/stay_awake

pkill -9 gptokeyb2
