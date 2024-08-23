#!/bin/sh
source /mnt/SDCARD/System/usr/trimui/scripts/common_launcher.sh
cpufreq.sh ondemand 1 6

echo $0 $*
progdir=`dirname "$0"`/drastic
cd $progdir



echo "=============================================="
echo "==================== DRASTIC ================="
echo "=============================================="


export HOME="$progdir"
#export SDL_AUDIODRIVER=dsp
./drastic "$*"
