#!/bin/sh

STATUS_FILE="/tmp/trimui_osd/toggle_fastforward/status"
CMD="/mnt/SDCARD/System/bin/thd --triggers /mnt/SDCARD/System/etc/thd_fastforward.conf /dev/input/event*"

if [ $# -eq 0 ] ; then
    mkdir -p "$(dirname "$STATUS_FILE")"
else
    PID=$(pgrep -f "thd.*thd_fastforward\.conf")

    if [ -n "$PID" ]; then
        kill "$PID"
        echo 0 > "$STATUS_FILE"
    else
        $CMD &
        echo 1 > "$STATUS_FILE"
    fi
fi
