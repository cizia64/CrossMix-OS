#!/bin/sh
source /mnt/SDCARD/System/usr/trimui/scripts/launchers/common_launcher.sh
cpufreq.sh conservative 0 6

cd "$RA_DIR"
HOME="$PWD" ./ra64.trimui -L .retroarch/cores/ffmpeg_libretro.so "$@"
