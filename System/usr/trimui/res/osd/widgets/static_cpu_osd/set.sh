#!/bin/sh

if [ -f /tmp/trimui_osd/osdd_show_up ]; then # avoid to launch CPU osd when main OSD is starting
    touch /tmp/hide_osdd
    if ! pgrep -f cpuinfo_osdd >/dev/null; then
        cd /mnt/SDCARD/System/usr/trimui/osd/
        ./cpuinfo_osdd &
    fi
    touch /tmp/show_osd3
fi
