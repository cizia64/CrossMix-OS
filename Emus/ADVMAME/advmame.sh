#!/bin/sh
echo $0 $*

cd "$(dirname "$0")"

export LD_LIBRARY_PATH="$PWD/lib:/mnt/SDCARD/System/lib:/usr/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

./cpufreq.sh

Gamefile=$(basename "$@")
HOME="$PWD" ./advmame "${Gamefile%.*}"
