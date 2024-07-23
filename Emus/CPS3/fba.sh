#!/bin/sh
source /mnt/SDCARD/System/usr/trimui/scripts/launchers/common_launcher.sh
cpufreq.sh ondemand 1 7

#disable netplay
NET_PARAM=

cd "$RA_DIR"

#HOME="$PWD" ./ra64.trimui -v $NET_PARAM -L $EMU_DIR/fbalpha2012_cps3_libretro.so "$@"
HOME="$PWD" ./ra64.trimui -v $NET_PARAM -L .retroarch/cores/fbalpha2012_libretro.so "$@"
