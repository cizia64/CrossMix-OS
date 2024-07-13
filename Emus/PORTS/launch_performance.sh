#!/bin/sh

source /mnt/SDCARD/System/etc/ex_config

echo ondemand > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
echo 1008000 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq
echo 2000000 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq

PORTS_DIR=/mnt/SDCARD/Roms/PORTS
cd $PORTS_DIR/

export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/mnt/SDCARD/System/lib"
/bin/sh "$@"
