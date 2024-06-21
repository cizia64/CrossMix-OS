#!/bin/sh
echo "============= scene CPU Performance ============"

normal_restored=false

while true; do
    case "$1" in
    1)
        # echo "cpu performance"
        if [ -f "/tmp/cmd_to_run.sh" ]; then
            echo performance >/sys/devices/system/cpu/cpufreq/policy0/scaling_governor
            echo -n "2000000" >/sys/devices/system/cpu/cpufreq/policy0/scaling_min_freq
            echo -n "2000000" >/sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq
            normal_restored=false
        fi
        ;;
    0)
        # echo "cpu normal"
        if [ "$normal_restored" = false ]; then
            echo ondemand >/sys/devices/system/cpu/cpufreq/policy0/scaling_governor
            echo -n "1008000" >/sys/devices/system/cpu/cpufreq/policy0/scaling_min_freq
            echo -n "2000000" >/sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq
            normal_restored=true
        fi
        ;;
    *) ;;
    esac
    sleep 5
done
