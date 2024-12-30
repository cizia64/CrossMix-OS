#!/bin/sh
source /mnt/SDCARD/System/usr/trimui/scripts/common_launcher.sh
cpufreq.sh ondemand 2 7

cd $RA_DIR/

realpath=$(realpath "$@")
HOME=$RA_DIR/ $RA_DIR/ra64.trimui -v -L $RA_DIR/.retroarch/cores/easyrpg_libretro.so "$realpath" &
activities add "$1" $!
