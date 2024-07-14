#!/bin/sh
echo performance > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
echo 1800000 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq
