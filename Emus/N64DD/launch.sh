#!/bin/sh
source /mnt/SDCARD/System/usr/trimui/scripts/common_launcher.sh
cpufreq.sh ondemand 5 7

cd /mnt/SDCARD/Emus/N64
export XDG_CONFIG_HOME="$PWD"
export XDG_DATA_HOME="$PWD"

cd mupen64plus
EMU_DIR="$PWD"


export LD_LIBRARY_PATH="$PM_DIR:$EMU_DIR:$LD_LIBRARY_PATH"

[ -f "/mnt/SDCARD/trimui/app/cmd_to_run.sh" ] && fb_disable_transparency

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

HOTKEY=guide $PM_DIR/gptokeyb2 -c "./defkeys.gptk" &

HOME=$EMU_DIR ./mupen64plus "$ROM_PATH" 2>&1

rm -f "$TEMP_ROM"

kill -9 $(pidof gptokeyb2)
