#!/bin/sh

if [ -f /tmp/trimui_osd/osdd_show_u3 ]; then # avoid to launch CPU osd when main OSD is starting
    touch /tmp/hide_osd3
    if ! pgrep -f cpuinfo_osdd >/dev/null; then
        cd /usr/trimui/osd/
        ./trimui_osdd &
    fi
    touch /tmp/show_osdd
fi
