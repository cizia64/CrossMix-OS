#!/bin/sh
echo $0 $*
source /mnt/SDCARD/System/usr/trimui/scripts/common_launcher.sh


export HOME=/mnt/SDCARD/Emus/MAME2010
export PATH="/mnt/SDCARD/System/bin${PATH:+:$PATH}"
export LD_LIBRARY_PATH="$HOME/lib:/mnt/SDCARD/System/lib:/usr/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

$HOME/cpufreq.sh

Gamefile=$(basename "$@")
advmame "${Gamefile%.*}"
