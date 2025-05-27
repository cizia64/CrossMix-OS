#!/bin/sh
export LD_LIBRARY_PATH="/usr/trimui/lib:$LD_LIBRARY_PATH"
PATH="/mnt/SDCARD/System/bin:$PATH"

if [ -f /usr/trimui/osd/trimui_osdd ]; then
    if ! pgrep -f nightmode_osdd >/dev/null; then
        cd /mnt/SDCARD/System/usr/trimui/osd/
        ./nightmode_osdd &
    fi
    touch /tmp/show_osd2

else
    /mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "No configurator, edit the nightmode.conf manually"
fi
