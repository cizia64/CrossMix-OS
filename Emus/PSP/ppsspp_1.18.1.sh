#!/bin/sh
source /mnt/SDCARD/System/usr/trimui/scripts/common_launcher.sh

cd PPSSPP_1.18.1
export LD_LIBRARY_PATH="/usr/trimui/lib:/usr/lib:/lib"

last_dowork=$(grep -i  "dowork 0x" "/tmp/log/messages" | tail -n 1)
if echo "$last_dowork" | grep -q "Perf." ; then
    cpufreq.sh ondemand 3 8 
else
    cpufreq.sh ondemand 3 6
fi

config_file="/mnt/SDCARD/Emus/PSP/PPSSPP_1.18.1/.config/ppsspp/PSP/SYSTEM/ppsspp.ini"

if echo "$last_dowork" | grep -q "Vulkan"; then
    sed -i '/^\[Graphics\]$/,/^\[/ s/GraphicsBackend = .*/GraphicsBackend = 3/' "$config_file"
else
    sed -i '/^\[Graphics\]$/,/^\[/ s/GraphicsBackend = .*/GraphicsBackend = 0/' "$config_file"
fi

if [ -f "/tmp/cmd_to_run.sh" ] && ! grep -q "dowork 0x" "/tmp/cmd_to_run.sh"; then
    sed -i "1s|^|echo \"$last_dowork\" > /tmp/log/messages\n|" "/tmp/cmd_to_run.sh"
fi

HOME=$PWD ./PPSSPPSDL_1.18.1 "$*"
