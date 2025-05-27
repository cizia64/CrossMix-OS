#!/bin/sh

OUTFILE="/tmp/crossmix_info/app_info.txt"


if [ -f "/tmp/trimui_osd/slider_cpu_preset/curpreset" ]; then
    CPU_MODE=$(cat "/tmp/trimui_osd/slider_cpu_preset/curpreset")
else
    CPU_MODE="-"
fi

# CPU
CPU_FREQ_KHZ=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq 2>/dev/null)
CPU_FREQ_MHZ=$((CPU_FREQ_KHZ / 1000))
CPU_GOV=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null)
CPU_TEMP_RAW=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null)
CPU_TEMP=$((CPU_TEMP_RAW / 1000))

# RAM
MEM_TOTAL=$(awk '/MemTotal/ {print int($2/1024)}' /proc/meminfo)
MEM_FREE=$(awk '/MemAvailable/ {print int($2/1024)}' /proc/meminfo)

# Battery
BAT_PATH="/sys/class/power_supply/axp2202-battery"
BAT_CAPACITY=$(cat "$BAT_PATH/capacity")
BAT_VOLT_RAW=$(cat "$BAT_PATH/voltage_now")
BAT_VOLT=$(awk "BEGIN {printf \"%.2f\", $BAT_VOLT_RAW / 1000000}")
[ "$BAT_VOLT" = "0.00" ] && BAT_VOLT="0"
BAT_HEALTH=$(cat "$BAT_PATH/health")
BAT_STATUS=$(cat "$BAT_PATH/status")
BAT_CURRENT_mA=$(cat "$BAT_PATH/constant_charge_current")
BAT_CURRENT_A=$(awk "BEGIN {printf \"%.2f\", $BAT_CURRENT_mA / 1000}")
BAT_TIME_FULL=$(cat "$BAT_PATH/time_to_full_now")
BAT_LEVEL=$(cat $BAT_PATH/capacity_level 2>/dev/null)

# Formating
if [ "$BAT_TIME_FULL" -gt 0 ]; then
    BAT_TIME_MIN=$((BAT_TIME_FULL / 60))
else
    BAT_TIME_MIN="?"
fi


{
    echo "mode  : $CPU_MODE"
    echo "speed : ${CPU_FREQ_MHZ} MHz"
    echo "gover.: $CPU_GOV"
    echo "Temp  : ${CPU_TEMP}°C"
    echo
    echo "${MEM_FREE} MB Free / ${MEM_TOTAL} MB"
    echo
    echo "level: ${BAT_LEVEL}: ${BAT_CAPACITY}% - ${BAT_VOLT}v"
    echo -n "${BAT_STATUS}"
    [ "$STATUS" = "Charging" ] && echo -n ":${BAT_CURRENT_A}A/h - ${BAT_TIME_MIN}mn"
    echo -e "\nhealth: ${BAT_HEALTH}"
} > "$OUTFILE"
