#!/bin/sh
echo $0 $*
source /mnt/SDCARD/System/usr/trimui/scripts/common_launcher.sh

EMU_DIR=/mnt/SDCARD/Emus/GBA
export LD_LIBRARY_PATH="$EMU_DIR/lib:/usr/lib:$LD_LIBRARY_PATH"
export XDG_CONFIG_HOME="$EMU_DIR/.config"

$EMU_DIR/cpufreq.sh

/mnt/SDCARD/Apps/PortMaster/PortMaster/gptokeyb "mgba" -c "/mnt/SDCARD/Emus/GBA/.config/mgba/mgba.gptk" &
sleep 1

$EMU_DIR/mgba "$@" 
kill gptokeyb
