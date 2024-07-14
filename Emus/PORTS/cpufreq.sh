#!/bin/sh

case "$1" in 
    "High Performance")
        MINFREQ=408000 # filler
        MAXFREQ=1800000
        GOVERNOR="performance"
        ;;
    "Balanced")
        MINFREQ=600000
        MAXFREQ=1608000
        GOVERNOR="ondemand"
        ;;
    "Battery Saver")
        MINFREQ=408000
        MAXFREQ=1200000
        GOVERNOR="conservative"
        ;;
esac

echo "$MINFREQ" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq
echo "$MAXFREQ" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq
echo "$GOVERNOR" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor