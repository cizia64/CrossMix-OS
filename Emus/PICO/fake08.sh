#!/bin/sh
echo $0 $*
cd "$(dirname "$0")"

source /mnt/SDCARD/System/usr/trimui/scripts/common_launcher.sh
./cpufreq.sh

romName=$(basename "$@")
romNameNoExtension=${romName%.*}

if [ "$romNameNoExtension" = "° Run Splore" ]; then
	sh "Pico8 Wrapper - Splore.sh"
	exit
fi

#disable netplay
NET_PARAM=

cd /mnt/SDCARD/RetroArch

HOME="$PWD" ./ra64.trimui -v $NET_PARAM -L .retroarch/cores/fake08_libretro.so "$@"
