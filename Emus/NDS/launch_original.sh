#!/bin/sh
source /mnt/SDCARD/System/usr/trimui/scripts/common_launcher.sh
echo $0 $*
progdir=`dirname "$0"`/drastic
cd $progdir



echo "=============================================="
echo "==================== DRASTIC ================="
echo "=============================================="

../performance.sh

export HOME="$progdir"
#export SDL_AUDIODRIVER=dsp
./drastic "$*"
