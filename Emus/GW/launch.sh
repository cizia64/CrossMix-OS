#!/bin/sh
source /mnt/SDCARD/System/usr/trimui/scripts/launchers/common_launcher.sh
cpufreq.sh ondemand 1 7


#disable netplay
NET_PARAM=

cd "$RA_DIR"
HOME="$PDW" ./ra64.trimui -v $NET_PARAM -L .retroarch/cores/gw_libretro.so "$@"
