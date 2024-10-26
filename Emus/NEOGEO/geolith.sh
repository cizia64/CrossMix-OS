#!/bin/sh
if [ ! "${1##*.}" = neo ]; then
  /mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "Geolith is only able to start roms with .neo extension." -fs 22 -k "A B START SELECT"
  exit 1
fi

source /mnt/SDCARD/System/usr/trimui/scripts/common_launcher.sh
cpufreq.sh ondemand 2 6


cd $RA_DIR/

HOME=$RA_DIR/ $RA_DIR/ra64.trimui -v -L $RA_DIR/.retroarch/cores/geolith_libretro.so "$@"
