#!/bin/sh
echo $0 $*

EMU_DIR=/mnt/SDCARD/Emus/GBA
export LD_LIBRARY_PATH="$EMU_DIR/lib:/usr/lib:$LD_LIBRARY_PATH"
export XDG_CONFIG_HOME="$EMU_DIR/.config"

$EMU_DIR/cpufreq.sh

/mnt/SDCARD/Apps/PortMaster/PortMaster/gptokeyb2 "mgba" -k "mgba" -c "/mnt/SDCARD/Emus/GBA/.config/mgba/mgba.gptk" &
sleep 0.3

$EMU_DIR/mgba "$@" 
kill gptokeyb2
