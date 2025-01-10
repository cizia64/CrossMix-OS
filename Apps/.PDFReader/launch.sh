#!/bin/sh
export LD_LIBRARY_PATH=$(dirname "$0")/libs:/mnt/SDCARD/System/lib:$LD_LIBRARY_PATH

cd $(dirname "$0")

/mnt/SDCARD/Apps/PortMaster/PortMaster/gptokeyb -1 "green" -c "./green.gptk" &
sleep 0.3

./green -fullscreen "$@"

pkill gptokeyb
