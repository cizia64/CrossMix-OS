#!/bin/sh
source /mnt/SDCARD/System/usr/trimui/scripts/common_launcher.sh
cpufreq.sh performance 7 7

cd "/mnt/SDCARD/Emus/DC/flycast_v1.0"

export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$PWD/lib"
export FLYCAST_BIOS_DIR="/mnt/SDCARD/BIOS/dc/"
export FLYCAST_DATA_DIR="$FLYCAST_BIOS_DIR"
export FLYCAST_CONFIG_DIR="$PWD/config/"
export HOME="$PWD"
export XDG_DATA_HOME="$FLYCAST_BIOS_DIR"
export XDG_CONFIG_HOME="$PWD/config/"

mkdir -p "$FLYCAST_BIOS_DIR/flycast"

./flycast "$@"
