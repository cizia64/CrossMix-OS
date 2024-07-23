#!/bin/sh
source /mnt/SDCARD/System/usr/trimui/scripts/launchers/common_launcher.sh
cpufreq.sh conservative 0 6

#disable netplay
NET_PARAM=

cd "$RA_DIR"
HOME="$PWD" ./ra64.trimui -v $NET_PARAM -L .retroarch/cores/ep128emu_core_libretro.so "$@"
