#!/bin/sh
source /mnt/SDCARD/System/usr/trimui/scripts/launchers/common_launcher.sh
cpufreq.sh conservative 0 6

cd "$RA_DIR"

HOME="$RA_DIR" ./ra64.trimui -v $NET_PARAM -L .retroarch/cores/fbalpha2012_libretro.so "$@"

#HOME="$PWD" ./ra64.trimui -v $NET_PARAM -L $EMU_DIR/fbalpha2012_cps1_libretro.so "$@"
