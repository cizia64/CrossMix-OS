#!/bin/sh
echo conservative > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
echo 408000 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq
echo 1080000 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq