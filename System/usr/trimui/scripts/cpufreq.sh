#!/bin/sh

governor="$1"
min_id="$2"
max_id="$3"
# If $4 is set, it means that the user wants to set the same governor for all cores
if [ "$4" = "all" ]; then
    for i in $(seq 0 $(($(nproc) - 1))); do
        echo 1 > /sys/devices/system/cpu/cpu$i/online
    done
fi

id_to_freq() {
    case $1 in
        0) echo 408000;;
        1) echo 600000;;
        2) echo 816000;;
        3) echo 1008000;;
        4) echo 1200000;;
        5) echo 1416000;;
        6) echo 1608000;;
        7) echo 1800000;;
        8) echo 2000000;;
    esac
}

echo $governor > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
echo $(id_to_freq $min_id) > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq
echo $(id_to_freq $max_id) > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq
