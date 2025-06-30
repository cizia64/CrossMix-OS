#!/bin/sh

STATUS_FILE="/tmp/trimui_osd/toggle_fastforward/status"
CMD="/mnt/SDCARD/System/bin/r2_fastforward /dev/input/event3"

if [ $# -eq 0 ]; then
    mkdir -p "$(dirname "$STATUS_FILE")"
else
    # Get PIDs of matching process
    PIDS=$(pgrep -f "r2_fastforward /dev/input/event3")

    if [ -n "$PIDS" ]; then
        echo "Killing r2_fastforward..."
        echo "$PIDS" | xargs kill
        echo 0 >"$STATUS_FILE"
    else
        echo "Launching r2_fastforward..."
        $CMD &
        echo 1 >"$STATUS_FILE"
    fi
fi
