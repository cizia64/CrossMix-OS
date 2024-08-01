#!/bin/sh
echo $0 $*

cd "$(dirname "$0")"
source /mnt/SDCARD/System/usr/trimui/scripts/common_launcher.sh

./cpufreq.sh
./effect.sh

cd /mnt/SDCARD/RetroArch

#disable netplay
NET_PARAM=

HOME="$PWD" ./ra64.trimui -v $NET_PARAM -L .retroarch/cores/flycast_libretro.so "$@"
