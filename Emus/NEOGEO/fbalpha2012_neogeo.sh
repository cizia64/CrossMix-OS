#!/bin/sh
if [ "${1##*.}" = neo ]; then $(dirname "$0")/geolith.sh "$1"; exit 0; fi

source /mnt/SDCARD/System/usr/trimui/scripts/common_launcher.sh
cpufreq.sh 2 6

cd $RA_DIR/

HOME=$RA_DIR/ $RA_DIR/ra64.trimui -v -L $RA_DIR/.retroarch/cores/fbalpha2012_neogeo_libretro.so "$@" &
activities add "$1" $!
