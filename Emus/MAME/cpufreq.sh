#!/bin/sh
echo performance > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
echo 2000000 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq
