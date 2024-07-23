#!/bin/sh

source /mnt/SDCARD/System/usr/trimui/scripts/launchers/common_launcher.sh
cpufreq.sh ondemand 5 7

cd mnt/SDCARD/Emus/N64/mupen64plus

CONFDIR="$PWD/conf/"
mkdir -p conf
export XDG_CONFIG_HOME="$CONFDIR"
export XDG_DATA_HOME="$CONFDIR"
export FRT_NO_EXIT_SHORTCUTS=FRT_NO_EXIT_SHORTCUTS


PATH=$PWD:$PATH
export LD_LIBRARY_PATH="$PWD/libs:$LD_LIBRARY_PATH"

case "$*" in
    *.n64|*.v64|*.z64|*.ndd) 
        ROM_PATH="$*" 
        ;;
    *.zip|*.7z)
        TEMP_ROM=$(mktemp)
        ROM_PATH="$TEMP_ROM"
        7zz e "$*" -so > "$TEMP_ROM"
        ;;
esac

echo gptokeyb -k mupen64plus -c "./defkeys.gptk" 
/mnt/SDCARD/Apps/PortMaster/PortMaster/gptokeyb -k mupen64plus -c "./defkeys.gptk" &

./mupen64plus "$ROM_PATH" 2>&1

rm -f "$TEMP_ROM"

$ESUDO kill -9 $(pidof gptokeyb)
