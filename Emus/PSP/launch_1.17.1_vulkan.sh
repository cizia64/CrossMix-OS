#!/bin/sh
echo $0 $*

cd "$(dirname "$0)"
./cpufreq.sh

echo "=============================================="
echo "==================== PPSSPP  ================="
echo "=============================================="

cd PPSSPP_1.17.1

# We set the Backend to Vulkan
config_file="/mnt/SDCARD/Emus/PSP/PPSSPP_1.17.1/.config/ppsspp/PSP/SYSTEM/ppsspp.ini"
sed -i '/^\[Graphics\]$/,/^\[/ s/GraphicsBackend = .*/GraphicsBackend = 3/' "$config_file"

#export SDL_AUDIODRIVER=dsp   //disable 20231031 for sound suspend issue
HOME="$PWD" ./PPSSPPSDL_vulkan "$*"
