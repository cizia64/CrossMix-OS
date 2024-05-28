#!/bin/sh
echo $0 $*
source /mnt/SDCARD/System/usr/trimui/scripts/FolderOverrideFinder.sh
RA_DIR=/mnt/SDCARD/RetroArch
EMU_DIR=/mnt/SDCARD/Emus/FC
cd $RA_DIR/

$EMU_DIR/cpufreq.sh

echo ====================================================================
echo $RA_DIR/.retroarch/cores/nestopia_libretro.so
echo ====================================================================

HOME=$RA_DIR/ $RA_DIR/ra64.trimui -v $NET_PARAM -L $RA_DIR/.retroarch/cores/nestopia_libretro.so "$@"

