#!/bin/sh
echo $0 $*

EMU_DIR=/mnt/SDCARD/Emus/NAOMI
FLYCAST_DIR=/mnt/SDCARD/Emus/DC/flycast

$EMU_DIR/cpufreq.sh
$EMU_DIR/effect.sh

cd "$FLYCAST_DIR"

export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:lib
export FLYCAST_BIOS_DIR="/mnt/SDCARD/BIOS/dc/"
export FLYCAST_DATA_DIR=$FLYCAST_BIOS_DIR
export FLYCAST_CONFIG_DIR="$FLYCAST_DIR/config/"

./flycast "$@"