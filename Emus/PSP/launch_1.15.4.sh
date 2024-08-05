#!/bin/sh
echo $0 $*
cd "$(dirname "$0")"

source /mnt/SDCARD/System/usr/trimui/scripts/common_launcher.sh
./cpufreq.sh

echo "=============================================="
echo "==================== PPSSPP  ================="
echo "=============================================="

cd PPSSPP_1.15.4

export LD_LIBRARY_PATH="${LD_LIBRARY_PATH:+$LD_LIBRARY_PATH:}$PWD"

HOME="$PWD" ./PPSSPPSDL "$*"
