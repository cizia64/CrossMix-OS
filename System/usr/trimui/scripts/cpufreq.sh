#!/bin/ash

governor="$1"
min_id="$2"
max_id="$3"

id_to_freq() {
	case $1 in
	0) echo 408000 ;;
	1) echo 600000 ;;
	2) echo 816000 ;;
	3) echo 1008000 ;;
	4) echo 1200000 ;;
	5) echo 1416000 ;;
	6) echo 1608000 ;;
	7) echo 1800000 ;;
	8) echo 2000000 ;;
	esac
}

if [ "$governor" != "interactive" ] && [ "$governor" != "ondemand" ] && [ "$governor" != "performance" ] && [ "$governor" != "powersave" ] && [ "$governor" != "conservative" ]; then
	echo "cpufreq.sh: Invalid governor."
	exit 1
elif [ $min_id -lt 0 ] || [ $min_id -gt 8 ]; then
	echo "cpufreq.sh: Invalid min frequency id."
	exit 1
elif [ $max_id -lt $min_id ] || [ $max_id -gt 8 ]; then
	echo "cpufreq.sh: Invalid max frequency id."
	exit 1
fi

min_freq=$(id_to_freq $min_id)
max_freq=$(id_to_freq $max_id)

echo "Setting CPU frequency to $governor, $min_freq - $max_freq kHz."
echo $governor >/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
if [ $min_freq -gt "$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq)" ]; then
    echo $max_freq >/sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq
    echo $min_freq >/sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq
else
    echo $min_freq >/sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq
    echo $max_freq >/sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq
fi
