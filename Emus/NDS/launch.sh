#!/bin/sh
echo $0 $*
progdir=`dirname "$0"`/drastic
cd $progdir
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$progdir

echo "=============================================="
echo "==================== DRASTIC  ================="
echo "=============================================="

echo 1608000 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq
echo performance > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor

export HOME=/mnt/SDCARD

./drastic "$*"
