#!/bin/sh
pid=$(pidof MainUI)
if [ -n "$pid" ]; then
    pkill -STOP runtrimui.sh 2>/dev/null
    kill -9 "$pid" &
    /mnt/SDCARD/System/bin/activities gui
    pkill -CONT runtrimui.sh 2>/dev/null
fi
