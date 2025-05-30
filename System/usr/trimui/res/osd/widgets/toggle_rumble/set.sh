#!/bin/sh

RUMBLE_STATE=$(/usr/trimui/bin/shmvar rumbleswitch)

mkdir -p "/tmp/trimui_osd/toggle_rumble"

if [ $# -eq 0 ]; then
    echo "$RUMBLE_STATE" > "/tmp/trimui_osd/toggle_rumble/status"
else
    if [ "$RUMBLE_STATE" -eq 1 ]; then
        echo 0 > "/tmp/trimui_osd/toggle_rumble/status"
        if [ ! -f /tmp/system/rumble_turn_off ]; then
            touch /tmp/system/rumble_turn_off
        fi

    elif [ "$RUMBLE_STATE" -eq 0 ]; then
        if [ ! -f /tmp/system/rumble_turn_on ]; then
            echo 1 > "/tmp/trimui_osd/toggle_rumble/status"
            touch /tmp/system/rumble_turn_on
            
            sleep 0.1
            echo -n 1 > /sys/class/gpio/gpio227/value
            sleep 0.1
            echo -n 0 > /sys/class/gpio/gpio227/value
        fi
    fi
fi
