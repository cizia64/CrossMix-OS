#!/bin/sh
source /mnt/SDCARD/System/usr/trimui/scripts/launchers/common_launcher.sh
cpufreq.sh conservative 0 6

cd "$RA_DIR"

#disable netplay
NET_PARAM=

HOME="$PWD" ./ra64.trimui -v $NET_PARAM -L .retroarch/cores/hatari_libretro.so "$@"

#HOME="$PWD" $RA_DIR/retroarch -v $NET_PARAM -L .retroarch/cores/hatari_libretro.so "$@"
#HOME="$PWD" $RA_DIR/retroarch -v $NET_PARAM -L $EMU_DIR/hatari_libretro.so "$@"
