#!/bin/sh
echo $0 $*
cd "$(dirname "$0")"
source /mnt/SDCARD/System/usr/trimui/scripts/common_launcher.sh
./cpufreq.sh

#disable netplay
NET_PARAM=

cd /mnt/SDCARD/RetroArch
HOME="$PWD" ./ra64.trimui -v "$NET_PARAM" -L .retroarch/cores/fceumm_libretro.so "$@"
