#!/bin/sh
echo $0 $*
progdir=`dirname "$0"`
progdir154=$progdir/PPSSPP_1.15.4
cd $progdir154
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$progdir154

echo "=============================================="
echo "==================== PPSSPP  ================="
echo "=============================================="

./cpufreq.sh

export HOME=$progdir154
./PPSSPPSDL "$*"
