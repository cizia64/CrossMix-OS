#!/bin/sh
echo $0 $*
cd "$(dirname "$0")"
./performance.sh

echo "=============================================="
echo "==================== DRASTIC ================="
echo "=============================================="

cd drastic
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH:+$LD_LIBRARY_PATH:}$PWD/lib"
export LD_PRELOAD="./libSDL2-2.0.so.0.2600.1"

#export SDL_AUDIODRIVER=dsp
HOME="$PWD" ./drastic "$*"
