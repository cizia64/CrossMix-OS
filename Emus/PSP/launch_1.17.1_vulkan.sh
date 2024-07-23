#!/bin/sh
source /mnt/SDCARD/System/usr/trimui/scripts/launchers/common_launcher.sh

performance=$(grep -i "dowork 0x" "/tmp/log/messages" | tail -n 1 | grep -i "Perf.")
if [ -z "$performance" ]; then
    cpufreq.sh ondemand 3 8 
else
    cpufreq.sh ondemand 3 6
fi

cd PPSSPP_1.17.1

# We set the Backend to Vulkan
config_file=".config/ppsspp/PSP/SYSTEM/ppsspp.ini"
sed -i '/^\[Graphics\]$/,/^\[/ s/GraphicsBackend = .*/GraphicsBackend = 3/' "$config_file"

#export SDL_AUDIODRIVER=dsp   //disable 20231031 for sound suspend issue
HOME="$PWD" ./PPSSPPSDL_vulkan "$*"
