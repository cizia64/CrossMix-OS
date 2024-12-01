#!/bin/sh
echo $0 $*
progdir=$(dirname "$0")
homedir=$(dirname "$1")
extension="${@##*.}"

if [ "$extension" = "launch" ]; then
	sh "$1"
	exit
fi

cd "$progdir"

export LD_LIBRARY_PATH=/lib:/lib64:/usr/lib:/mnt/SDCARD/System/lib/:/mnt/SDCARD/Apps/PortMaster/PortMaster:LD_LIBRARY_PATH

/mnt/SDCARD/Apps/PortMaster/PortMaster/gptokeyb2 -1 "mpv" -c "keys.gptk" &
sleep 0.4

echo 1 >/tmp/stay_awake
HOME="$progdir" /mnt/SDCARD/System/bin/mpv "$@" --fullscreen --audio-buffer=1 --terminal=no # --lavfi-complex="[aid1]asplit[ao][a]; [a]showcqt[vo]" --script=/mnt/SDCARD/Emus/VIDEOS/.config/mpv/metadata_osd.lua  #--autofit=100%x1280    # for music: --geometry=720   # visu: --lavfi-complex="[aid1]asplit[ao][a]; [a]showcqt[vo]"
rm /tmp/stay_awake

pkill -9 gptokeyb2
