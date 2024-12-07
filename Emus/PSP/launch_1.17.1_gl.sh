#!/bin/sh
source /mnt/SDCARD/System/usr/trimui/scripts/common_launcher.sh

# cwd is EMU_DIR
cd PPSSPP_1.17.1

performance=$(grep -i "dowork 0x" "/tmp/log/messages" | tail -n 1 | grep -i "Perf.") # We detect the performance mode from the label which have been selected in launcher menu
if [ -z "$performance" ]; then
    cpufreq.sh ondemand 3 8 
else
    cpufreq.sh ondemand 3 6
fi

# We set the Backend to OpenGL
config_file="/mnt/SDCARD/Emus/PSP/PPSSPP_1.17.1/.config/ppsspp/PSP/SYSTEM/ppsspp.ini"
sed -i '/^\[Graphics\]$/,/^\[/ s/GraphicsBackend = .*/GraphicsBackend = 0/' "$config_file"

#export SDL_AUDIODRIVER=dsp   //disable 20231031 for sound suspend issue
HOME=$PWD ./PPSSPPSDL_gl "$*" &
activities add "$1" $!
