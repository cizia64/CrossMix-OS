#!/bin/sh

case "$1" in 
    performance)
        MINFREQ=1008000
        MAXFREQ=2000000
        GOVERNOR="ondemand"
        ;;
    balanced)
        MINFREQ=600000
        MAXFREQ=1416000
        GOVERNOR="ondemand"
        ;;
    powersave)
        MINFREQ=408000
        MAXFREQ=1008000
        GOVERNOR="conservative"
        ;;
esac

echo "$MINFREQ" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq
echo "$MAXFREQ" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq
echo "$GOVERNOR" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor