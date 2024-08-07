#!/bin/sh
echo $0 $*


export HOME=/mnt/SDCARD/Emus/ADVMAME
export PATH="/mnt/SDCARD/System/bin${PATH:+:$PATH}"
export LD_LIBRARY_PATH="$HOME/lib:/mnt/SDCARD/System/lib:/usr/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

$HOME/cpufreq.sh

Gamefile=$(basename "$@")
advmame "${Gamefile%.*}"
