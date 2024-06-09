#!/bin/sh
echo $0 $*

echo performance >/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
echo 1416000 >/sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq

# Launch tool script file
echo "*** Launching $1 ***"
"$1" 

# we don't memorize System Tools scripts in recent list
recentlist=/mnt/SDCARD/Roms/recentlist.json
sed -i '1d' $recentlist
sync