#!/bin/sh
echo $0 $*
progdir=`dirname "$0"`
progdir171_vulkan=$progdir/PPSSPP_1.17.1_vulkan
cd $progdir171_vulkan
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$progdir171_vulkan

echo "=============================================="
echo "==================== PPSSPP  ================="
echo "=============================================="

../cpufreq.sh
../cpuswitch.sh


export HOME=$progdir171_vulkan
./PPSSPPSDL_vulkan "$*"
