#!/bin/sh
source /mnt/SDCARD/System/usr/trimui/scripts/launchers/common_launcher.sh
cpufreq.sh performance 7 7
./effect.sh


cd flycast

export LD_LIBRARY_PATH="${LD_LIBRARY_PATH:+$LS_LIBRARY_PARH:}$PWD/lib"
export FLYCAST_BIOS_DIR="/mnt/SDCARD/BIOS/dc/"
export FLYCAST_DATA_DIR=$FLYCAST_BIOS_DIR
export FLYCAST_CONFIG_DIR="$PWD/config/"

./flycast "$@"
