#!/bin/sh
echo $0 $*
source /mnt/SDCARD/System/usr/trimui/scripts/common_launcher.sh

RA_DIR=/mnt/SDCARD/RetroArch
progdir=$(dirname "$0")
romdir=$(dirname "$1")
romname=$(basename "$1")
romNameNoExtension=${romname%.*}

$EMU_DIR/performance.sh


#disable netplay
NET_PARAM=

cd $RA_DIR/

HOME=$RA_DIR/ $RA_DIR/ra64.trimui -v $NET_PARAM -L $RA_DIR/.retroarch/cores/km_daphne_xtreme_libretro.so "$romdir/${romNameNoExtension}.zip" "${@:2}"


