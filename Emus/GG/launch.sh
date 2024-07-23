#!/bin/sh
source /mnt/SDCARD/System/usr/trimui/scripts/launchers/common_launcher.sh
cpufreq.sh ondemand 1 7


#disable netplay
NET_PARAM=

cd "$RA_DIR"
HOME="$PWD" ./ra64.trimui -v $NET_PARAM -L .retroarch/cores/genesis_plus_gx_libretro.so "$@"
