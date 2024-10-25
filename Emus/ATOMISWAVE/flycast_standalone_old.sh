#!/bin/sh
echo $0 $*

EMU_DIR=/mnt/SDCARD/Emus/DC

$EMU_DIR/cpufreq.sh
$EMU_DIR/effect.sh

cd "$EMU_DIR/flycast_old"

export HOME="$EMU_DIR/flycast_old"
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:lib
export FLYCAST_BIOS_PATH="/mnt/SDCARD/BIOS/dc/"

./flycast "$@"