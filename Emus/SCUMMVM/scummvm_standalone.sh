#!/bin/sh
source /mnt/SDCARD/System/usr/trimui/scripts/common_launcher.sh
cpufreq.sh ondemand 5 7

# ScummVM binary extraction
if [ ! -f "/mnt/SDCARD/Emus/SCUMMVM/ScummVM/scummvm" ]; then
    /mnt/SDCARD/System/bin/7zz x "/mnt/SDCARD/Emus/SCUMMVM/ScummVM/scummvm.7z" -o"/mnt/SDCARD/Emus/SCUMMVM/ScummVM" && rm "/mnt/SDCARD/Emus/SCUMMVM/ScummVM/scummvm.7z"
fi


export SDL_GAMECONTROLLERCONFIG_FILE=./gamecontrollerdb.txt
export LD_LIBRARY_PATH=./lib:/mnt/SDCARD/System/lib/:/usr/lib:LD_LIBRARY_PATH

Rom="$@"
RomPath=$(dirname "$1")
romName=$(basename "$@")
romNameNoExtension=${romName%.*}

if [ "$romName" = "° Run ScummVM.launch" ]; then
	mv "$Rom" "$RomPath/$romNameNoExtension.squashfs"
	/mnt/SDCARD/System/usr/trimui/scripts/reset_list.sh "SCUMMVM"
fi

if ! [ "$romNameNoExtension" = "° Run ScummVM" ]; then
	game=$(cat "$1")
fi

if [ "$romName" = "° Import ScummVM Games.launch" ]; then
	/mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -i "bg-info.png" -m "Importing ScummVM games."
	sh "$Rom"
	exit
fi

cd $(dirname "$0")/ScummVM
HOME=$(dirname "$0")/ScummVM
./scummvm $game
