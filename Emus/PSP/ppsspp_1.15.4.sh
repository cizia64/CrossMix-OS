#!/bin/sh
source /mnt/SDCARD/System/usr/trimui/scripts/common_launcher.sh
export LD_LIBRARY_PATH="/usr/trimui/lib" # "/mnt/SDCARD/System/lib" = segfault

# cwd is EMU_DIR
cd PPSSPP_1.15.4

performance=$(grep -i "dowork 0x" "/tmp/log/messages" | tail -n 1 | grep -i "Perf.")
if [ -n "$performance" ]; then
    cpufreq.sh ondemand 3 8
else
    cpufreq.sh ondemand 3 6
fi

if [ -f "/tmp/cmd_to_run.sh" ] && ! grep -q "dowork 0x" "/tmp/cmd_to_run.sh"; then
    sed -i "1s|^|echo \"$performance\" > /tmp/log/messages\n|" "/tmp/cmd_to_run.sh"
fi

HOME=$PWD ./PPSSPPSDL "$*"
