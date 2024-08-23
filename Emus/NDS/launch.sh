#!/bin/sh
source /mnt/SDCARD/System/usr/trimui/scripts/common_launcher.sh
echo $0 $*
progdir=`dirname "$0"`/drastic
cd $progdir
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$progdir/lib
export LD_PRELOAD=./libSDL2-2.0.so.0.2600.1

echo "=============================================="
echo "==================== DRASTIC ================="
echo "=============================================="

../performance.sh

export HOME="$progdir"
#export SDL_AUDIODRIVER=dsp
./drastic "$*"
