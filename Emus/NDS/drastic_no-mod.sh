#!/bin/sh
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
