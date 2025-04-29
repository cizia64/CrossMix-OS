#!/bin/sh

PATH="/mnt/SDCARD/System/bin:$PATH"

# tracks LCD state
STATE_FILE="/tmp/lcd_state"

# display settings goes from 0 to 10
sttbrt=`cat /mnt/UDISK/system.json|jq .brightness`
# lcd brightness goes from 0 to 255, but our "real" max is 230
disbrt=$(printf "%.0f" `echo "$sttbrt * 23"|bc`)

# we make sure settings "0" is still visible
if [ "$disbrt" == "0" ]; then
  disbrt=4
fi

# Turn on the LCD
echo lcd0 >/sys/kernel/debug/dispdbg/name
echo setbl >/sys/kernel/debug/dispdbg/command
echo $disbrt >/sys/kernel/debug/dispdbg/param
echo 1 >/sys/kernel/debug/dispdbg/start
# Update the state
echo "on" >"$STATE_FILE"
# Turn on leds
ledset=$(/usr/trimui/bin/shmvar 10)
scale=$(expr $ledset \* 4)
echo -n $scale >/sys/class/led_anim/max_scale
