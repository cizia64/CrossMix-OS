#!/bin/sh
echo $0 $*

echo performance > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
echo 2000000 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq
     

source /mnt/SDCARD/System/usr/trimui/scripts/FolderOverrideFinder.sh
RA_DIR=/mnt/SDCARD/RetroArch
EMU_DIR=/mnt/SDCARD/Emus/FC

$EMU_DIR/cpufreq.sh


cd $RA_DIR/

#disable netplay
NET_PARAM=

HOME=$RA_DIR/ $RA_DIR/ra64.trimui -v $NET_PARAM -L $RA_DIR/.retroarch/cores/mesen_libretro.so "$@"
