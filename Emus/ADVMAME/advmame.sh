#!/bin/sh
source /mnt/SDCARD/System/usr/trimui/scripts/common_launcher.sh
cpufreq.sh ondemand 4 7

export LD_LIBRARY_PATH="$PWD/lib:/mnt/SDCARD/System/lib:/usr/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

Gamedir=$(dirname "$@")
Gamefile=$(basename "$@")
HOME="$PWD" ./advmame4 -dir_rom "$Gamedir" "${Gamefile%.*}"
