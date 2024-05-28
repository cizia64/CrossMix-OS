#!/bin/sh
echo $0 $*

# Launch tool script file
echo "******************************************************************-*-*- $1"
"$1" 

# we don't memorize System Tools scripts in recent list
recentlist=/mnt/SDCARD/Roms/recentlist.json
sed -i '1d' $recentlist
sync