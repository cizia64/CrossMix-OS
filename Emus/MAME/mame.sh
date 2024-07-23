#!/bin/sh
# Warning : This launcher must be started with libFLAC.so.8 in LD_LIBRARY_PATH
source /mnt/SDCARD/System/usr/trimui/scripts/launchers/common_launcher.sh
cpufreq.sh conservative 0 6

#disable netplay
NET_PARAM=

cd "$RA_DIR"
HOME="$PWD" ./ra64.trimui -v $NET_PARAM -L .retroarch/cores/mame_libretro.so "$@"
