#!/bin/sh
source /mnt/SDCARD/System/usr/trimui/scripts/common_launcher.sh
cpufreq.sh ondemand 5 7

Rom="$@"
RomPath=$(dirname "$1")
romName=$(basename "$@")
romNameNoExtension=${romName%.*}

if [ "$romName" = "° Run ScummVM.launch" ]; then
	mv "$Rom" "$RomPath/$romNameNoExtension.squashfs"
	/mnt/SDCARD/System/usr/trimui/scripts/reset_list.sh "SCUMMVM"
fi

if [ "$romName" = "° Import ScummVM Games.launch" ]; then
	/mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -i "bg-info.png" -m "Importing ScummVM games."
	sh "$Rom"
	exit
fi

cd $RA_DIR/
HOME=$RA_DIR/ $RA_DIR/ra64.trimui -v -L $RA_DIR/.retroarch/cores/scummvm_libretro-2.9.so "$@"
