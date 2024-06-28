#!/bin/sh
echo $0 $*
source /mnt/SDCARD/System/usr/trimui/scripts/FolderOverrideFinder.sh
RA_DIR=/mnt/SDCARD/RetroArch
EMU_DIR=/mnt/SDCARD/Emus/PICO8

$EMU_DIR/cpufreq.sh


Rom="$@"
RomPath=$(dirname "$1")
RomDir=$(basename "$RomPath")
romName=$(basename "$@")
romNameNoExtension=${romName%.*}

if [ "$romNameNoExtension" = "° Run Splore" ]; then
	sh "/mnt/SDCARD/Emus/PICO/Pico8 Wrapper - Splore.sh"
	exit
fi


cd $RA_DIR/

#disable netplay
NET_PARAM=

HOME=$RA_DIR/ $RA_DIR/ra64.trimui -v $NET_PARAM -L $RA_DIR/.retroarch/cores/fake08_libretro.so "$@"
