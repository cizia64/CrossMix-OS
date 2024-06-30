#!/bin/sh
echo "===================================="
echo $0 $*
source /mnt/SDCARD/System/usr/trimui/scripts/FolderOverrideFinder.sh
RA_DIR=/mnt/SDCARD/RetroArch
EMU_DIR=/mnt/SDCARD/Emus/GB
cd $RA_DIR/

#disable netplay
NET_PARAM=


HOME=$RA_DIR/ $RA_DIR/ra64.trimui -v $NET_PARAM -L $RA_DIR/.retroarch/cores/tgbdual_libretro.so "$@"

