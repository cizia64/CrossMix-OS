#!/bin/sh
echo ondemand > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
echo 408000 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq
echo 1608000 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq