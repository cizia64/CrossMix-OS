#!/bin/sh
echo $0 $*
RA_DIR=/mnt/SDCARD/RetroArch
EMU_DIR=/mnt/SDCARD/Emus/N64

$EMU_DIR/performance.sh

cd $RA_DIR/

echo 1608000 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq
echo performance > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor

#disable netplay
NET_PARAM=

HOME=$RA_DIR/ $RA_DIR/ra64.trimui -v $NET_PARAM -L $RA_DIR/.retroarch/cores/mupen64plus_libretro.so "$*"
