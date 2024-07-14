#!/bin/sh

echo "$0 $*"
progdir=$(dirname "$0")

export LD_LIBRARY_PATH=${LD_LIBRARY_PATH:+$LD_LIBRARY_PATH:}"$progdir"
export HOME="$progdir"

echo "=============================================="
echo "==================== PPSSPP  ================="
echo "=============================================="

performance=$(grep -i "dowork 0x" "/tmp/log/messages" | tail -n 1 | grep -i "Perf.") # We detect the performance mode from the label which have been selected in launcher menu
if [ -n "$performance" ]; then
    echo "Performance mode selected"
	echo ondemand > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
	echo 1008000 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq
	echo 2000000 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq
	echo 1 > /sys/devices/system/cpu/cpu0/online
	echo 1 > /sys/devices/system/cpu/cpu1/online
	echo 1 > /sys/devices/system/cpu/cpu2/online
	echo 1 > /sys/devices/system/cpu/cpu3/online
fi

# We set the Backend to Vulkan
config_file="$progdir/.config/ppsspp/PSP/SYSTEM/ppsspp171.ini"
sed -i '/^\[Graphics\]$/,/^\[/ s/GraphicsBackend = .*/GraphicsBackend = 3/' "$config_file"

#export SDL_AUDIODRIVER=dsp   //disable 20231031 for sound suspend issue
"$progdir"/PPSSPPSDL171_vulkan --config="$config_file" "$*"
