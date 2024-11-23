#!/bin/sh
source /mnt/SDCARD/System/usr/trimui/scripts/common_launcher.sh
cpufreq.sh ondemand 2 7

cd $RA_DIR/

HOME=$RA_DIR/ $RA_DIR/ra64.trimui -v -L $RA_DIR/.retroarch/cores/genesis_plus_gx_libretro.so "$@" &
activities add "$1" $!
