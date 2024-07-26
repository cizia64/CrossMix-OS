#!/bin/sh
echo $0 $*


RA_DIR=/mnt/SDCARD/RetroArch
EMU_DIR=/mnt/SDCARD/Emus/ATOMISWAVE

source /mnt/SDCARD/System/usr/trimui/scripts/common_launcher.sh
source /mnt/SDCARD/System/usr/trimui/scripts/save_launcher.sh "$EMU_DIR" "$@"

$EMU_DIR/cpufreq.sh
$EMU_DIR/effect.sh

cd $RA_DIR/

#disable netplay
NET_PARAM=

HOME=$RA_DIR/ $RA_DIR/ra64.trimui -v -L $RA_DIR/.retroarch/cores/flycast_libretro.so "$@"
