#!/bin/sh
#echo "===================================="
echo $0 $*
source /mnt/SDCARD/System/usr/trimui/scripts/common_launcher.sh
cpufreq.sh ondemand 2 6
RA_DIR=/mnt/SDCARD/RetroArch
EMU_DIR=/mnt/SDCARD/Emus/ZXS
cd $RA_DIR/

#disable netplay
NET_PARAM=

HOME=$RA_DIR/ $RA_DIR/ra64.trimui -v $NET_PARAM -L $RA_DIR/.retroarch/cores/fuse_libretro.so "$@"

#HOME=$RA_DIR/ $RA_DIR/retroarch -v $NET_PARAM -L $RA_DIR/.retroarch/cores/fuse_libretro.so "$@"
#HOME=$RA_DIR/ $RA_DIR/retroarch -v $NET_PARAM -L $EMU_DIR/fuse_libretro.so "$@"
