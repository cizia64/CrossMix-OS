#!/bin/sh
source /mnt/SDCARD/System/usr/trimui/scripts/common_launcher.sh
cpufreq.sh ondemand 3 7


RomFullPath=$1
extension="${RomFullPath##*.}"
if [ "$extension" = "launch" ]; then
    "$@"
	exit
fi


cd $RA_DIR/
HOME=$RA_DIR/ $RA_DIR/ra64.trimui -v -L $RA_DIR/.retroarch/cores/zc210_libretro.so "$@"
