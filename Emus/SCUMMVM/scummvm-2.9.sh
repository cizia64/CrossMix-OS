#!/bin/sh
echo $0 $*
source /mnt/SDCARD/System/usr/trimui/scripts/FolderOverrideFinder.sh
RA_DIR=/mnt/SDCARD/RetroArch
EMU_DIR=/mnt/SDCARD/Emus/SCUMMVM

Rom="$@"
RomPath=$(dirname "$1")
RomDir=$(basename "$RomPath")
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
	/mnt/SDCARD/System/bin/sdl2imgshow \
		-i "$Current_bg" \
		-f "/mnt/SDCARD/System/resources/DejaVuSans.ttf" \
		-s 30 \
		-c "220,220,220" \
		-t "Importing ScummVM games." &
	sh "$Rom"
	sleep 0.3
	pkill -f sdl2imgshow
	exit
fi

$EMU_DIR/performance.sh

cd $RA_DIR/

#disable netplay
NET_PARAM=

HOME=$RA_DIR/ $RA_DIR/ra64.trimui -v $NET_PARAM -L $RA_DIR/.retroarch/cores/scummvm_libretro-2.9.so "$@"
