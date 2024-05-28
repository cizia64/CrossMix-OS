#!/bin/sh

/mnt/SDCARD/System/bin/sdl2imgshow \
    -i "/usr/trimui/res/skin/bg.png" \
    -f "/mnt/SDCARD/System/resources/DejaVuSans.ttf" \
    -s 40 \
    -c "220,220,220" \
    -t "Sorting favorites..." &

set -eu

SORT=/usr/bin/sort
ROMS_DIR=/mnt/SDCARD/Roms
FAV_FILE=favourite2.json

cd $ROMS_DIR
cp $FAV_FILE $FAV_FILE.bak
$SORT $FAV_FILE >$FAV_FILE.tmp
mv $FAV_FILE.tmp $FAV_FILE
sync
sync
sync

sleep 1
pkill -f sdl2imgshow
