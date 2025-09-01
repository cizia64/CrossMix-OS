#!/bin/sh
source /mnt/SDCARD/System/usr/trimui/scripts/common_launcher.sh

# cwd is EMU_DIR
cd PPSSPP_1.19.3
export LD_LIBRARY_PATH="$PWD/lib:$LD_LIBRARY_PATH"

performance=$(grep -i "dowork 0x" "/tmp/log/messages" | tail -n 1 | grep -i "Perf.") # We detect the performance mode from the label which have been selected in launcher menu
if [ -n "$performance" ]; then
    cpufreq.sh ondemand 3 8
else
    cpufreq.sh ondemand 3 6
fi

config_file="/mnt/SDCARD/Emus/PSP/PPSSPP_1.19.3/.config/ppsspp/PSP/SYSTEM/ppsspp.ini"

if grep -i "dowork 0x" "/tmp/log/messages" | tail -n 1 | grep -qi "Vulkan"; then
    sed -i '/^\[Graphics\]$/,/^\[/ s/GraphicsBackend = .*/GraphicsBackend = 3/' "$config_file"
else
    sed -i '/^\[Graphics\]$/,/^\[/ s/GraphicsBackend = .*/GraphicsBackend = 0/' "$config_file"
fi

if [ -f "/tmp/cmd_to_run.sh" ] && ! grep -q "dowork 0x" "/tmp/cmd_to_run.sh"; then
    sed -i "1s|^|echo \"$performance\" > /tmp/log/messages\n|" "/tmp/cmd_to_run.sh"
fi

# We set the Backend to OpenGL

#export SDL_AUDIODRIVER=dsp   //disable 20231031 for sound suspend issue
HOME=$PWD ./PPSSPPSDL "$*"
