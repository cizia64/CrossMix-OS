#!/bin/sh

/mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "Sorting favorites..."
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
