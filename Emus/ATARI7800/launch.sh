#!/bin/sh
source /mnt/SDCARD/System/usr/trimui/scripts/launchers/common_launcher.sh
cpufreq.sh conservative 0 6

cd "$RA_DIR"

HOME="$PWD" ./ra64.trimui -v $NET_PARAM -L .retroarch/cores/prosystem_libretro.so "$@"

#HOME="$PWD" $RA_DIR/retroarch -v $NET_PARAM -L .retroarch/cores/snes9x2002_libretro.so "$@"
#HOME="$PWD" $RA_DIR/retroarch -v $NET_PARAM -L $EMU_DIR/snes9x2010_libretro.so "$@"
