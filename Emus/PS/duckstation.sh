#!/bin/sh
source /mnt/SDCARD/System/usr/trimui/scripts/launchers/common_launcher.sh
cpufreq.sh ondemand 5 7


if ! find "/mnt/SDCARD/BIOS" -maxdepth 1 -iname "scph*" -o -iname "psxonpsp660.bin" -o -iname "ps*.bin" | grep -q .; then
	infoscreen.sh -i bg-exit.png -m "No bios found, DuckStation will probably not work." -k " "
fi


#disable netplay
NET_PARAM=

cd "$RA_DIR"
HOME="$PWD" ./ra64.trimui -v $NET_PARAM -L .retroarch/cores/duckstation_libretro.so "$@"
