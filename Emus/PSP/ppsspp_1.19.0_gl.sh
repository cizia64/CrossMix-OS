#!/bin/sh
source /mnt/SDCARD/System/usr/trimui/scripts/common_launcher.sh

# cwd is EMU_DIR
cd PPSSPP

performance=$(grep -i "dowork 0x" "/tmp/log/messages" | tail -n 1 | grep -i "Perf.") # We detect the performance mode from the label which have been selected in launcher menu
if [ -n "$performance" ]; then
    cpufreq.sh ondemand 3 8
else
    cpufreq.sh ondemand 3 6
fi

if [ -f "/tmp/cmd_to_run.sh" ] && ! grep -q "dowork 0x" "/tmp/cmd_to_run.sh"; then
    sed -i "1s|^|echo \"$performance\" > /tmp/log/messages\n|" "/tmp/cmd_to_run.sh"
fi

# We set the Backend to OpenGL
config_file="/mnt/SDCARD/Emus/PSP/PPSSPP/.config/ppsspp/PSP/SYSTEM/ppsspp.ini"
sed -i '/^\[Graphics\]$/,/^\[/ s/GraphicsBackend = .*/GraphicsBackend = 0/' "$config_file"

#export SDL_AUDIODRIVER=dsp   //disable 20231031 for sound suspend issue
HOME=$PWD ./PPSSPPSDL_1.19.0 "$*"
