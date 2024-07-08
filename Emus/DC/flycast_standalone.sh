#!/bin/sh
echo $0 $*
source /mnt/SDCARD/System/usr/trimui/scripts/FolderOverrideFinder.sh
EMU_DIR=/mnt/SDCARD/Emus/DC

$EMU_DIR/cpufreq.sh
$EMU_DIR/effect.sh

cd "$EMU_DIR/flycast"

export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:lib
./flycast "$@"