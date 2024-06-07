#!/bin/sh
echo $0 $*
source /mnt/SDCARD/System/usr/trimui/scripts/FolderOverrideFinder.sh
progdir=`dirname "$0"`
cd $progdir
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$progdir

echo "=============================================="
echo "==================== PPSSPP  ================="
echo "=============================================="

$EMU_DIR/cpufreq.sh
$EMU_DIR/cpuswitch.sh

export HOME=/mnt/SDCARD
export SDL_AUDIODRIVER=dsp
./PPSSPPSDL "$*"
