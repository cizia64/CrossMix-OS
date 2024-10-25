#!/bin/sh
source /mnt/SDCARD/System/usr/trimui/scripts/common_launcher.sh
cpufreq.sh ondemand 4 7

# cwd is EMU_DIR
cd drastic

LAUNCHER=$(grep -i "dowork 0x" "/tmp/log/messages" | tail -n 1)

if ! echo "$LAUNCHER" | grep -iq "No Overlay"; then
    export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$PWD/lib"
    export LD_PRELOAD="./libSDL2-2.0.so.0.2600.1"
fi

#export SDL_AUDIODRIVER=dsp

if echo "$LAUNCHER" | grep -iq "Nearest"; then
    echo "Using nearest neighbour scaling"
    ./drastic_nn "$*"
else
    echo "Using bilinear scaling"
    ./drastic "$*"
fi
