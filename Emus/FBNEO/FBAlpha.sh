#!/bin/sh
source /mnt/SDCARD/System/usr/trimui/scripts/launchers/common_launcher.sh
cpufreq.sh ondemand 1 6


cd "$RA_DIR"

HOME="$PWD" ./ra64.trimui -v $NET_PARAM -L .retroarch/cores/fbalpha_libretro.so "$@"
