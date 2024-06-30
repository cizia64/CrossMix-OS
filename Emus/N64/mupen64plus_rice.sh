#!/bin/sh

echo $0 $*

EMU_DIR=/mnt/SDCARD/Emus/N64/mupen64plus
CONFDIR="$EMU_DIR/confr/"
mkdir -p "$EMU_DIR/confr"
export XDG_CONFIG_HOME="$CONFDIR"
export XDG_DATA_HOME="$CONFDIR"
export FRT_NO_EXIT_SHORTCUTS=FRT_NO_EXIT_SHORTCUTS

./performance.sh
PWD=$PWD
cd $EMU_DIR/

PATH=$PWD:$EMU_DIR:$PATH
export LD_LIBRARY_PATH=$PWD/libs:$EMU_DIR/libs:$LD_LIBRARY_PATH

echo $EMU_DIR/gptokeyb -k mupen64plus -c "./defkeys.gptk" 
$EMU_DIR/gptokeyb -k mupen64plus -c "./defkeys.gptk" &

./mupen64plus "$*" 2>&1

$ESUDO kill -9 $(pidof gptokeyb)
