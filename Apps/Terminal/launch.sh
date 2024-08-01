#!/bin/bash

custom_intputd=$(ls -la /usr/trimui/bin | grep "trimui_inputd -> /usr/trimui/bin/trimui_inputd_patched")

if [ -n "$custom_intputd" ]; then
    /mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "Patched inputd break the terminal. Switch back to original inputd to use it." -fs "22" -k "A B START SELECT"
    exit 1
fi

progdir=$(dirname "$0")
cd $progdir
 ./SimpleTerminal
