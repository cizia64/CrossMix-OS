#!/bin/sh
echo $0 $*
source /mnt/SDCARD/System/usr/trimui/scripts/FolderOverrideFinder.sh
progdir=`dirname "$0"`
progdir154=$progdir/PPSSPP_1.15.4
cd $progdir154
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$progdir154

echo "=============================================="
echo "==================== PPSSPP  ================="
echo "=============================================="

../performance.sh

export HOME=$progdir154
#export SDL_AUDIODRIVER=dsp   //disable 20231031 for sound suspend issue
./PPSSPPSDL "$*"
