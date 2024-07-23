#!/bin/sh
source /mnt/SDCARD/System/usr/trimui/scripts/launchers/common_launcher.sh
cpufreq.sh conservative 0 6

romName=$(basename "$@")
romNameNoExtension=${romName%.*}

if [ "$romNameNoExtension" = "° Run Splore" ]; then
	sh "Pico8 Wrapper - Splore.sh"
	exit
fi

#disable netplay
NET_PARAM=

cd "$RA_DIR"
HOME="$PWD" ./ra64.trimui -v $NET_PARAM -L .retroarch/cores/fake08_libretro.so "$@"
