#!/bin/sh

echo $0 $*

EMU_DIR=/mnt/SDCARD/Emus/N64/mupen64plus
CONFDIR="$EMU_DIR/conf/"
mkdir -p "$EMU_DIR/conf"
export XDG_CONFIG_HOME="$CONFDIR"
export XDG_DATA_HOME="$CONFDIR"
export FRT_NO_EXIT_SHORTCUTS=FRT_NO_EXIT_SHORTCUTS

./performance.sh
PWD=$PWD
cd $EMU_DIR/

PATH=$PWD:$EMU_DIR:$PATH
export LD_LIBRARY_PATH=$PWD/libs:$EMU_DIR/libs:$LD_LIBRARY_PATH

case "$*" in
    *.n64|*.v64|*.z64|*.ndd) 
        ROM_PATH="$*" 
        ;;
    *.zip|*.7z)
        TEMP_ROM=$(mktemp)
        ROM_PATH="$TEMP_ROM"
        /mnt/SDCARD/System/bin/7zz e "$*" -so > "$TEMP_ROM"
        ;;
esac

echo $EMU_DIR/gptokeyb -k mupen64plus -c "./defkeys.gptk" 
$EMU_DIR/gptokeyb -k mupen64plus -c "./defkeys.gptk" &

./mupen64plus "$ROM_PATH" 2>&1

rm -f "$TEMP_ROM"

$ESUDO kill -9 $(pidof gptokeyb)