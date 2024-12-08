#!/bin/sh
source /mnt/SDCARD/System/usr/trimui/scripts/common_launcher.sh

# cwd is EMU_DIR
cd PPSSPP_1.15.4

performance=$(grep -i "dowork 0x" "/tmp/log/messages" | tail -n 1 | grep -i "Perf.")
if [ -z "$performance" ]; then
    cpufreq.sh ondemand 3 8 
else
    cpufreq.sh ondemand 3 6
fi

HOME=$PWD ./PPSSPPSDL "$*"
