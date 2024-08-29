#!/bin/sh
source /mnt/SDCARD/System/usr/trimui/scripts/common_launcher.sh
RA_DIR=/mnt/SDCARD/RetroArch
EMU_DIR=/mnt/SDCARD/Emus/ARCADE_FBNEO

$EMU_DIR/cpufreq.sh

Gamename="$(basename "$1")"
TMP_DIR=/mnt/SDCARD/Roms/roms_best_vertival
mkdir $TMP_DIR
TMP_ROM="$TMP_DIR/$Gamename"
mv "$1" "$TMP_ROM"

cd "$RA_DIR/"
HOME=$RA_DIR/ $RA_DIR/ra64.trimui -v $NET_PARAM -L $RA_DIR/.retroarch/cores/fbneo_libretro.so "$1"

mv "$TMP_ROM" "$1"
rmdir "$TMP_DIR"
