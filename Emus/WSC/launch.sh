#!/bin/sh
source /mnt/SDCARD/System/usr/trimui/scripts/launchers/common_launcher.sh
cpufreq.sh 0 6

NET_PARAM=

cd "$RA_DIR"
HOME="$PWD" ./ra64.trimui -v $NET_PARAM -L .retroarch/cores/mednafen_wswan_libretro.so "$@"

#HOME="$PWD" $RA_DIR/retroarch -v $NET_PARAM -L .retroarch/cores/mednafen_wswan_libretro.so "$@"
#HOME="$PWD" $RA_DIR/retroarch -v $NET_PARAM -L $EMU_DIR/mednafen_wswan_libretro.so "$@"
