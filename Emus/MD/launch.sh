#!/bin/sh
echo "=======================================================================:::"
echo $0 $*
source /mnt/SDCARD/System/usr/trimui/scripts/FolderOverrideFinder.sh
RA_DIR=/mnt/SDCARD/RetroArch
EMU_DIR=/mnt/SDCARD/Emus/MD
cd $RA_DIR/

source /mnt/SDCARD/System/usr/trimui/scripts/FolderOverrideFinder.sh



# HOME=$RA_DIR/ $RA_DIR/ra64.trimui -v $NET_PARAM -L $RA_DIR/.retroarch/cores/picodrive_libretro.so "$1" $2
HOME=$RA_DIR/ $RA_DIR/ra64.trimui -v $NET_PARAM -L $RA_DIR/.retroarch/cores/picodrive_libretro.so "$@"
# eval "HOME=$RA_DIR/ $RA_DIR/ra64.trimui -v $NET_PARAM -L $RA_DIR/.retroarch/cores/picodrive_libretro.so $*"
# HOME=$RA_DIR/ $RA_DIR/ra64.trimui -v $NET_PARAM -L $RA_DIR/.retroarch/cores/picodrive_libretro.so --appendconfig /mnt/SDCARD/RetroArch/.retroarch/config/PicoDrive/MD.cfg "$2"

#HOME=$RA_DIR/ $RA_DIR/retroarch -v $NET_PARAM -L $RA_DIR/.retroarch/cores/genesis_plus_gx_libretro.so "$@"
