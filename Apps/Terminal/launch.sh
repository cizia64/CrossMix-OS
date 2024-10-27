#!/bin/bash

# Fix slowdown caused by moded inputd
touch /var/trimui_inputd/sticks_disabled

if [ "$#" -gt 0 ]; then
 /mnt/SDCARD/Apps/Terminal/SimpleTerminal "$@"
else
  progdir=$(dirname "$0")
  cd $progdir
  ./SimpleTerminal
fi

rm /var/trimui_inputd/sticks_disabled
