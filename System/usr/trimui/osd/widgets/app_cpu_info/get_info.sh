#!/bin/sh

OUTFILE="/tmp/crossmix_info/app_cpu_info.txt"

if [ -f "/tmp/trimui_osd/slider_cpu_preset/curpreset" ]; then
    CPU_MODE=$(cat "/tmp/trimui_osd/slider_cpu_preset/curpreset")
else
    CPU_MODE="-"
fi

# CPU
CPU_FREQ_KHZ=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq 2>/dev/null)
CPU_FREQ_MHZ=$((CPU_FREQ_KHZ / 1000))
CPU_GOV=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null)

CPU_MIN_FREQ_KHZ=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq 2>/dev/null)
CPU_MIN_FREQ_MHZ=$((CPU_MIN_FREQ_KHZ / 1000))

CPU_MAX_FREQ_KHZ=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq 2>/dev/null)
CPU_MAX_FREQ_MHZ=$((CPU_MAX_FREQ_KHZ / 1000))

CPU_ACTIVE_COUNT=$(grep -c '^processor' /proc/cpuinfo)

CPU_TEMP_RAW=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null)
CPU_TEMP=$((CPU_TEMP_RAW / 1000))

{
    echo "Mode            : $CPU_MODE"
    echo "CPU speed   : ${CPU_FREQ_MHZ} MHz"
    echo
    echo "Governor      : $CPU_GOV"
    echo "Min freq.      : ${CPU_MIN_FREQ_MHZ} MHz"
    echo "Max freq.     : ${CPU_MAX_FREQ_MHZ} MHz"
    echo "Active CPUs :  $CPU_ACTIVE_COUNT"
    echo
    echo "Temp            : ${CPU_TEMP}°C"
} >"$OUTFILE"
