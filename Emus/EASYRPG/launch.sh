#!/bin/sh
#echo "===================================="
source /mnt/SDCARD/System/usr/trimui/scripts/launchers/common_launcher.sh
cpufreq.sh ondemand 1 6

cd "$RA_DIR"

#disable netplay
NET_PARAM=

HOME="$PWD" ./ra64.trimui -v $NET_PARAM -L .retroarch/cores/easyrpg_libretro.so "$@"

#HOME="$PWD" $RA_DIR/retroarch -v $NET_PARAM -L .retroarch/cores/easyrpg_libretro.so "$@"
#HOME="$PWD" $RA_DIR/retroarch -v $NET_PARAM -L $EMU_DIR/easyrpg_libretro.so "$@"
