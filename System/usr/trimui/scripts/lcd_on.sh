#!/bin/sh

# we need `jq`
PATH="/mnt/SDCARD/System/bin:$PATH"

# tracks LCD state
STATE_FILE="/tmp/lcd_state"

# display settings goes from 0 to 10
sttbrt=`cat /mnt/UDISK/system.json|jq .brightness`
# lcd brightness goes from 0 to 255
disbrt=$(printf "%.0f" `echo "$sttbrt * 25.5"|bc`)

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