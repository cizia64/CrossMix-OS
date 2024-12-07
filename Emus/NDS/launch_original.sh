#!/bin/sh
source /mnt/SDCARD/System/usr/trimui/scripts/common_launcher.sh
cpufreq.sh ondemand 4 7

# cwd is EMU_DIR
cd drastic
export HOME="$PWD"

#export SDL_AUDIODRIVER=dsp
./drastic "$*" &
activities add "$1" $!
