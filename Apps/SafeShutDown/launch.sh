#!/bin/sh

cd $(dirname "$0")
./show.elf ./ssd.png

sleep 1

echo ondemand > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
echo 1008000 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq
echo 1008000 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq

sleep 2
unmount /mnt/SDCARD

poweroff
