#!/bin/sh
echo $0 $*

cd "$(dirname "$0")"
source /mnt/SDCARD/System/usr/trimui/scripts/common_launcher.sh

./cpufreq.sh
./effect.sh


cd /mnt/SDCARD/Emus/DC/flycast

export LD_LIBRARY_PATH=${LD_LIBRARY_PATH:+$LD_LIBRARY_PATH:}:lib
export FLYCAST_BIOS_DIR="/mnt/SDCARD/BIOS/dc/"
export FLYCAST_DATA_DIR="$FLYCAST_BIOS_DIR"
export FLYCAST_CONFIG_DIR="$PWD/config/"

./flycast "$@"
