#!/bin/sh
source /mnt/SDCARD/System/usr/trimui/scripts/FolderOverrideFinder.sh
RA_DIR=/mnt/SDCARD/RetroArch
EMU_DIR=/mnt/SDCARD/Emus/PGM
cd $RA_DIR/

$EMU_DIR/cpufreq.sh

HOME=$RA_DIR/ $RA_DIR/ra64.trimui -v $NET_PARAM -L $RA_DIR/.retroarch/cores/fbalpha2012_libretro.so "$@"
#HOME=$RA_DIR/ $RA_DIR/ra64.trimui -v $NET_PARAM -L $EMU_DIR/fbneo_libretro.so "$@"