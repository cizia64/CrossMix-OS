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

freq_to_id() {
	case $1 in
	408000) echo 0 ;;
	600000) echo 1 ;;
	816000) echo 2 ;;
	1008000) echo 3 ;;
	1200000) echo 4 ;;
	1416000) echo 5 ;;
	1608000) echo 6 ;;
	1800000) echo 7 ;;
	2000000) echo 8 ;;
	esac
}

# display current CPU settings and usage examples
show_info() {
	read current_governor </sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
	read current_min_freq </sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq
	read current_max_freq </sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq

	min_id=$(freq_to_id "$current_min_freq")
	max_id=$(freq_to_id "$current_max_freq")

	cat <<-EOF
		========================================================================
		Usage examples:
		---------------
		  cpufreq.sh performance 3 7    # Set governor to 'performance', only max freq will be applied to 1800000 kHz
		  cpufreq.sh ondemand 1 5       # Set governor to 'ondemand', min freq to 600000 kHz, max freq to 1416000 kHz
		  cpufreq.sh powersave 0 2      # Set governor to 'powersave', min freq to 408000 kHz, max freq to 816000 kHz
		========================================================================
		Current CPU settings:
		---------------------
		  Governor: $current_governor
		  Min Frequency: $min_id = ${current_min_freq} kHz
		  Max Frequency: $max_id = ${current_max_freq} kHz
		========================================================================
	EOF
}

# without arguments, display current cpu settings and examples
if [ -z "$governor" ]; then
	show_info
	exit 0
fi

# Validate provided arguments
if [ "$governor" != "interactive" ] && [ "$governor" != "ondemand" ] && [ "$governor" != "performance" ] && [ "$governor" != "powersave" ] && [ "$governor" != "conservative" ]; then
	echo "cpufreq.sh: Invalid governor."
	exit 1
elif [ $min_id -lt 0 ] || [ $min_id -gt 8 ]; then
	echo "cpufreq.sh: Invalid min frequency ID."
	exit 1
elif [ $max_id -lt $min_id ] || [ $max_id -gt 8 ]; then
	echo "cpufreq.sh: Invalid max frequency ID."
	exit 1
fi

min_freq=$(id_to_freq $min_id)
max_freq=$(id_to_freq $max_id)

echo "Setting CPU frequency to $governor, $min_freq - $max_freq kHz."

# Update CPU settings
echo $governor >/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
if [ $min_freq -gt "$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq)" ]; then
	echo $max_freq >/sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq
	echo $min_freq >/sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq
else
	echo $min_freq >/sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq
	echo $max_freq >/sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq
fi
