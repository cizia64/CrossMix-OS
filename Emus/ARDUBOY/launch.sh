#!/bin/sh
#echo "===================================="
echo $0 $*
source /mnt/SDCARD/System/usr/trimui/scripts/FolderOverrideFinder.sh
RA_DIR=/mnt/SDCARD/RetroArch
EMU_DIR=/mnt/SDCARD/Emus/ARDUBOY
cd $RA_DIR/

#disable netplay
NET_PARAM=

if grep -i "dowork 0x" "/tmp/log/messages" | tail -n 1 | grep -iq "Arduous"; then
    CORE_FILE="$RA_DIR/.retroarch/cores/arduous_libretro.so"
else
    CORE_FILE="$RA_DIR/.retroarch/cores/ardens_libretro.so"
fi

HOME=$RA_DIR/ $RA_DIR/ra64.trimui -v $NET_PARAM -L "$CORE_FILE" "$@"

#HOME=$RA_DIR/ $RA_DIR/retroarch -v $NET_PARAM -L $RA_DIR/.retroarch/cores/arduous_libretro.so "$@"
#HOME=$RA_DIR/ $RA_DIR/retroarch -v $NET_PARAM -L $EMU_DIR/arduous_libretro.so "$@"