#!/bin/sh
echo $0 $*
cd "$(dirname "$0")"

source /mnt/SDCARD/System/usr/trimui/scripts/common_launcher.sh

Rom="$@"
RomPath=$(dirname "$1")
romName=$(basename "$@")
romNameNoExtension=${romName%.*}

if [ "$romName" = "° Run ScummVM.launch" ]; then
	mv "$Rom" "$RomPath/$romNameNoExtension.squashfs"
	rm "/mnt/SDCARD/Roms/SCUMMVM/SCUMMVM_cache7.db"
fi

if [ "$romName" = "° Import ScummVM Games.launch" ]; then
	Current_Theme=$(/usr/trimui/bin/systemval theme)
	Current_bg="$Current_Theme/skin/bg.png"
	if [ ! -f "$Current_bg" ]; then
		Current_bg="/mnt/SDCARD/trimui/res/skin/transparent.png"
	fi
	/mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -i "$Current_bg" -m "Importing ScummVM games."
	sh "$Rom"
	sleep 0.3
	exit
fi

./cpufreq.sh


#disable netplay
NET_PARAM=

cd /mnt/SDCARD/RetroArch
HOME="$PWD" ./ra64.trimui -v "$NET_PARAM" -L .retroarch/cores/scummvm_libretro.so "$@"
