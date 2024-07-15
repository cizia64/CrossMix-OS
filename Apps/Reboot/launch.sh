#!/bin/sh

if [[ $EUID -ne 0 ]]; then
   exit 1
fi


sync
sleep  0.3
/mnt/SDCARD/System/bin/shutdown -r
