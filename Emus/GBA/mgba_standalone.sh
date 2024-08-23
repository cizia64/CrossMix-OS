#!/bin/sh
source /mnt/SDCARD/System/usr/trimui/scripts/common_launcher.sh
cpufreq.sh conservative 0 6

echo $0 $*

EMU_DIR=/mnt/SDCARD/Emus/GBA
export LD_LIBRARY_PATH="/mnt/SDCARD/System/lib:$EMU_DIR/lib:/usr/lib:$LD_LIBRARY_PATH"
export XDG_CONFIG_HOME="$EMU_DIR/.config"


/mnt/SDCARD/Apps/PortMaster/PortMaster/gptokeyb2 "mgba" -k "mgba" -c "/mnt/SDCARD/Emus/GBA/.config/mgba/mgba.gptk" &
sleep 0.3

$EMU_DIR/mgba "$@" 
kill -9 $(pidof gptokeyb2)
