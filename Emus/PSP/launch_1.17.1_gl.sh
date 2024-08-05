#!/bin/sh
echo $0 $*
cd "$(dirname "$0")"

source /mnt/SDCARD/System/usr/trimui/scripts/common_launcher.sh
./cpufreq.sh

echo "=============================================="
echo "==================== PPSSPP  ================="
echo "=============================================="

cd PPSSPP_1.17.1

# We set the Backend to OpenGL
config_file="$PWD/.config/ppsspp/PSP/SYSTEM/ppsspp.ini"
sed -i '/^\[Graphics\]$/,/^\[/ s/GraphicsBackend = .*/GraphicsBackend = 0/' "$config_file"


#export SDL_AUDIODRIVER=dsp   //disable 20231031 for sound suspend issue
HOME="$PWD" ./PPSSPPSDL_gl "$*"
