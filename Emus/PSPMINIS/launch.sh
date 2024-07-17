#!/bin/sh
echo $0 $*
source /mnt/SDCARD/System/usr/trimui/scripts/common_launcher.sh
progdir=`dirname "$0"`
cd $progdir
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$progdir

echo "=============================================="
echo "==================== PPSSPP  ================="
echo "=============================================="

echo performance > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor

export HOME=/mnt/SDCARD
export SDL_AUDIODRIVER=dsp
./PPSSPPSDL "$*"
