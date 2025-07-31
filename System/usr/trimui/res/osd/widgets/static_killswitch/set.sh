#!/bin/sh
echo "click:"$1


detached()
{
/mnt/SDCARD/System/bin/sendkey /dev/input/event3 B 2
/mnt/SDCARD/System/usr/trimui/scripts/cmd_to_run_killer.sh
}

detached &

