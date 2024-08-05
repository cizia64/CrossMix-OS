#!/bin/sh
echo $0 $*
cd "$(dirname "$0")"

source /mnt/SDCARD/System/usr/trimui/scripts/common_launcher.sh
./performance.sh

echo "=============================================="
echo "==================== DRASTIC ================="
echo "=============================================="

cd drastic

#export SDL_AUDIODRIVER=dsp
HOME="$PWD" ./drastic "$*"
