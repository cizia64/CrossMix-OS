#!/bin/sh
cd "$(dirname "$0")"

source /mnt/SDCARD/System/usr/trimui/scripts/common_launcher.sh
./cpufreq.sh


cd /mnt/SDCARD/RetroArch

#HOME=$RA_DIR/ $RA_DIR/ra64.trimui -v $NET_PARAM -L $EMU_DIR/fbalpha2012_cps2_libretro.so "$@"
HOME="$PWD" ./ra64.trimui -v $NET_PARAM -L .retroarch/cores/fbalpha2012_libretro.so "$@"
