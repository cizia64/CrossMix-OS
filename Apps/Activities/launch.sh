#!/bin/sh
echo $0 $*

cd "$(dirname "$0")"

display=$(fbset | grep ^mode | cut -d "\"" -f 2)
if [ "$display" = "1280x720-64" ]; then
    sed -iE 's/^device=.*$/device=tsp' data/config.ini
else
    sed -iE 's/^device=.*$/device=brick' data/config.ini
fi

/mnt/SDCARD/System/bin/activities gui
