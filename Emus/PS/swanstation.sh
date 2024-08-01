#!/bin/sh
echo $0 $*
cd "$(dirname "$0")"

source /mnt/SDCARD/System/usr/trimui/scripts/common_launcher.sh
./cpufreq.sh Performance

cd /mnt/SDCARD/RetroArch

if ! find "/mnt/SDCARD/BIOS" -maxdepth 1 -iname "scph*" -o -iname "psxonpsp660.bin" -o -iname "ps*.bin" | grep -q .; then
	/mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -i bg-exit.png -m "No bios found, SwanStation will probably not work." -k " "
fi

#disable netplay
NET_PARAM=

HOME="$PWD" ./ra64.trimui -v "$NET_PARAM" -L .retroarch/cores/swanstation_libretro.so "$@"
