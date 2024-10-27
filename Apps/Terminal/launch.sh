#!/bin/bash

# Fix slowdown caused by inputd.v2
touch /var/trimui_inputd/sticks_disabled

progdir=$(dirname "$0")
cd $progdir
 ./SimpleTerminal

rm /var/trimui_inputd/sticks_disabled
