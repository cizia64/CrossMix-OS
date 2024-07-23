#!/bin/sh
source /mnt/SDCARD/System/usr/trimui/scripts/launchers/common_launcher.sh
cpufreq.sh ondemand 1 7


cd "$RA_DIR"

#force using fbneo
HOME="$PWD" ./ra64.trimui -v $NET_PARAM -L .retroarch/cores/fbneo_libretro.so "$@"
