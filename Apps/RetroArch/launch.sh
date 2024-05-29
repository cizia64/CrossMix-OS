#!/bin/sh
echo $0 $*
RA_DIR=/mnt/SDCARD/RetroArch
cd $RA_DIR/

export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/mnt/SDCARD/System/lib
echo $LD_LIBRARY_PATH

HOME=$RA_DIR/ $RA_DIR/ra64.trimui -v
