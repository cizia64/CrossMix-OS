#!/bin/sh
source /mnt/SDCARD/System/usr/trimui/scripts/launchers/common_launcher.sh
cpufreq.sh ondemand 3 6


cd PPSSPP/
export SDL_AUDIODRIVER=dsp
HOME="$PWD" ./PPSSPPSDL_gl "$*"
