#!/bin/sh
source /mnt/SDCARD/System/usr/trimui/scripts/common_launcher.sh
cpufreq.sh ondemand 4 7

# cwd is EMU_DIR
cd drastic

#export SDL_AUDIODRIVER=dsp
HOME=$PWD ./drastic "$*"
