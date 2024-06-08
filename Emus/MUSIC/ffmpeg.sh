#!/bin/sh
RA_DIR=/mnt/SDCARD/RetroArch
EMU_DIR=/mnt/SDCARD/Emus/VIDEOS
cd $RA_DIR/

$EMU_DIR/cpufreq.sh

HOME=$RA_DIR/ $RA_DIR/ra64.trimui -L $RA_DIR/.retroarch/cores/ffmpeg_libretro.so "$@"
