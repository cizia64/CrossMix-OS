#!/bin/sh

STATUS_FILE="/tmp/trimui_osd/toggle_fastforward/status"
CMD="/mnt/SDCARD/System/bin/r2_fastforward /dev/input/event3"

if [ $# -eq 0 ]; then
    mkdir -p "$(dirname "$STATUS_FILE")"
else

    # If gambatte is running, do not enable FF
    if pgrep -f "gambatte_libretro.so" >/dev/null; then
        ./show_info_msg_extra_long.sh "One key fast forward not required for this core."
        echo 0 >"$STATUS_FILE"
        exit 0
    fi

    # Check if r2_fastforward is already running
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
