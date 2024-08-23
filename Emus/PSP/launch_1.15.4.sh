#!/bin/sh
source /mnt/SDCARD/System/usr/trimui/scripts/common_launcher.sh
echo $0 $*
progdir=`dirname "$0"`
progdir154=$progdir/PPSSPP_1.15.4
cd "$progdir154"
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$progdir154
echo "=============================================="
echo "==================== PPSSPP  ================="
echo "=============================================="



performance=$(grep -i "dowork 0x" "/tmp/log/messages" | tail -n 1 | grep -i "Perf.")
if [ -z "$performance" ]; then
    cpufreq.sh ondemand 3 8 
else
    cpufreq.sh ondemand 3 6
fi


export HOME=$progdir154
./PPSSPPSDL "$*"

echo "*************************************************************"
