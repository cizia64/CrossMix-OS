#!/bin/sh
echo $0 $*
source /mnt/SDCARD/System/usr/trimui/scripts/FolderOverrideFinder.sh
EMU_DIR=/mnt/SDCARD/Emus/ATOMISWAVE
FLYCAST_DIR=/mnt/SDCARD/Emus/DC/flycast

$EMU_DIR/cpufreq.sh
$EMU_DIR/effect.sh

cd "$FLYCAST_DIR"

export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:lib
export FLYCAST_DATA_DIR="$FLYCAST_DIR/data/"
export FLYCAST_CONFIG_DIR="$FLYCAST_DIR/config/"

./flycast "$@"