#!/bin/sh
source /mnt/SDCARD/System/usr/trimui/scripts/launchers/common_launcher.sh
cpufreq.sh ondemand 5 7

Rom="$@"
RomPath=$(dirname "$1")
romName=$(basename "$@")
romNameNoExtension=${romName%.*}

if [ "$romName" = "° Run ScummVM.launch" ]; then
	mv "$Rom" "$RomPath/$romNameNoExtension.squashfs"
	rm "/mnt/SDCARD/Roms/SCUMMVM/SCUMMVM_cache7.db"
fi

if [ "$romName" = "° Import ScummVM Games.launch" ]; then
	Current_Theme=$(systemval theme)
	Current_bg="$Current_Theme/skin/bg.png"
	if [ ! -f "$Current_bg" ]; then
		Current_bg="/mnt/SDCARD/trimui/res/skin/transparent.png"
	fi
	infoscreen.sh -i "$Current_bg" -m "Importing ScummVM games."
	sh "$Rom"
	sleep 0.3
	exit
fi



#disable netplay
NET_PARAM=

cd "$RA_DIR"
HOME="$PWD" ./ra64.trimui -v $NET_PARAM -L .retroarch/cores/scummvm_libretro-2.9.so "$@"
