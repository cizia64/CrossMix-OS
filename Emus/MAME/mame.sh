#!/bin/sh
# required to load this Mame 0.259 (require "libFLAC.so.8")
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH:+$LD_LIBRARY_PATH:}/mnt/SDCARD/System/lib

echo $0 $*
cd "$(dirname "$0")"

source /mnt/SDCARD/System/usr/trimui/scripts/common_launcher.sh

./cpufreq.sh

#disable netplay
NET_PARAM=

cd /mnt/SDCARD/RetroArch
HOME="$PWD" ./ra64.trimui -v "$NET_PARAM" -L .retroarch/cores/mame_libretro.so "$@"
