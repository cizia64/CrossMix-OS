#!/bin/sh
echo $0 $*

source /mnt/SDCARD/System/usr/trimui/scripts/common_launcher.sh
cpufreq.sh performance 7 7

EMU_DIR=/mnt/SDCARD/Emus/DC


cd "$EMU_DIR/flycast_v2.4"

export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/mnt/SDCARD/Emus/DC/flycast_v1.0/lib"
export FLYCAST_BIOS_DIR="/mnt/SDCARD/BIOS/dc/"
export FLYCAST_DATA_DIR="$FLYCAST_BIOS_DIR/flycast/"
export FLYCAST_CONFIG_DIR="$EMU_DIR/flycast_v2.4/config/"
export HOME="$EMU_DIR/flycast_v2.4/"
export XDG_DATA_HOME="$FLYCAST_BIOS_DIR/flycast/"
export XDG_CONFIG_HOME="$EMU_DIR/flycast_v2.4/config/"	

mkdir -p "$FLYCAST_BIOS_DIR/flycast"

./flycast "$@"
