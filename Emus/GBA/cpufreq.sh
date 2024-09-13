#!/bin/sh
echo ondemand > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
echo 1008000 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq

if [ "$1" = "Performance" ]; then
    echo 1608000 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq
fi
