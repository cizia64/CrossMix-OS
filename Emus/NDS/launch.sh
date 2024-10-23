#!/bin/sh
source /mnt/SDCARD/System/usr/trimui/scripts/common_launcher.sh
echo $0 $*
progdir=`dirname "$0"`/drastic
cd $progdir

LAUNCHER=$(grep -i "dowork 0x" "/tmp/log/messages" | tail -n 1)

if ! echo "$LAUNCHER" | grep -iq "No Overlay"; then
    export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$progdir/lib"
    export LD_PRELOAD="./libSDL2-2.0.so.0.2600.1"
fi

echo "=============================================="
echo "==================== DRASTIC ================="
echo "=============================================="

../performance.sh

export HOME="$progdir"
#export SDL_AUDIODRIVER=dsp

DRASTIC_BINARY="./drastic"
if echo "$LAUNCHER" | grep -iq "Nearest"; then
    DRASTIC_BINARY="./drastic_nn"
    echo "Using nearest neighbour scaling"
else
    echo "Using bilinear scaling"
fi

$DRASTIC_BINARY "$*"