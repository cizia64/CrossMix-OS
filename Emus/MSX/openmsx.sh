#!/bin/sh

OM_DIR=/mnt/SDCARD/Emus/MSX2/openmsx
EMU_DIR=/mnt/SDCARD/Emus/MSX2

ROM_FILE=$(realpath "$1")

cd $OM_DIR


export OPENMSX_SYSTEM_DATA=$PWD/share
export HOME=$EMU_DIR

exec bin/openmsx -machine C-BIOS_MSX1 "$ROM_FILE"
