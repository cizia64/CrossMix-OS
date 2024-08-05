#!/bin/sh
echo "===================================="
echo $0 $*
cd "$(dirname "$0")"

source /mnt/SDCARD/System/usr/trimui/scripts/common_launcher.sh
./cpufreq.sh

cd /mnt/SDCARD/RetroArch

HOME="$PWD" ./ra64.trimui -v $NET_PARAM -L .retroarch/cores/picodrive_libretro.so "$@"
