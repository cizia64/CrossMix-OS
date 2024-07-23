#!/bin/sh
source /mnt/SDCARD/System/usr/trimui/scripts/launchers/common_launcher.sh
export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$EMU_DIR"

#echo performance > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
#swapon /mnt/SDCARD/App/swap/swap.img
./OpenBOR "$1"
#swapoff /mnt/SDCARD/App/swap/swap.img
