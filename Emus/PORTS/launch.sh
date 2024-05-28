#!/bin/sh

source /mnt/SDCARD/System/etc/ex_config

PORTS_DIR=/mnt/SDCARD/Roms/PORTS
cd $PORTS_DIR/

/bin/sh "$@"
