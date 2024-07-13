#!/bin/sh

source /mnt/SDCARD/System/etc/ex_config
EMU_DIR="/mnt/SDCARD/Emus/PORTS"

if grep -i "dowork 0x" "/tmp/log/messages" | tail -n 1 | grep -iq "High Performance"; then
    CPU_PROFILE=performance
elif grep -i "dowork 0x" "/tmp/log/messages" | tail -n 1 | grep -iq "Battery Saver"; then
    CPU_PROFILE=powersave
else
    CPU_PROFILE=balanced
fi

$EMU_DIR/cpufreq.sh "$CPU_PROFILE"

PORTS_DIR=/mnt/SDCARD/Roms/PORTS
cd "$PORTS_DIR"

export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/mnt/SDCARD/System/lib"
/bin/sh "$@"