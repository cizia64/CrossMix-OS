#!/bin/sh
export LD_LIBRARY_PATH=$(dirname "$0")/libs:/mnt/SDCARD/System/lib:$LD_LIBRARY_PATH

cd $(dirname "$0")

/mnt/SDCARD/Apps/PortMaster/PortMaster/gptokeyb -k "reader" -c "./reader.gptk" &

RESOLUTION=$("/mnt/SDCARD/Apps/PortMaster/PortMaster/sdl_resolution.aarch64" 2>/dev/null | grep -a 'Current' | awk -F ': ' '{print $2}')
DISPLAY_WIDTH=$(echo "$RESOLUTION" | cut -d'x' -f 1)
DISPLAY_HEIGHT=$(echo "$RESOLUTION" | cut -d'x' -f 2)
export SCREEN_WIDTH=$DISPLAY_WIDTH
export SCREEN_HEIGHT=$DISPLAY_HEIGHT

sleep 0.6

./reader

kill -9 $(pidof gptokeyb)
