#!/bin/sh
source /mnt/SDCARD/System/usr/trimui/scripts/common_launcher.sh
cpufreq.sh ondemand 2 7

progdir=$(dirname "$0")
romdir=$(dirname "$1")
romname=$(basename "$1")
romNameNoExtension=${romname%.*}


cd $RA_DIR/

HOME=$RA_DIR/ $RA_DIR/ra64.trimui -v -L $RA_DIR/.retroarch/cores/km_daphne_xtreme_libretro.so "$romdir/${romNameNoExtension}.zip" "${@:2}" &
activities add "$1" $!
