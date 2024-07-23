#!/bin/sh
source /mnt/SDCARD/System/usr/trimui/scripts/launchers/common_launcher.sh
cpufreq.sh ondemand 0 6

cd drastic/

#export SDL_AUDIODRIVER=dsp
HOME="$PWD" ./drastic "$*"
