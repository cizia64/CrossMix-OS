#!/bin/sh

# tracks LCD state
STATE_FILE="/tmp/lcd_state"

# Turn off the LCD
echo lcd0 >/sys/kernel/debug/dispdbg/name
echo setbl >/sys/kernel/debug/dispdbg/command
echo 0 >/sys/kernel/debug/dispdbg/param
echo 1 >/sys/kernel/debug/dispdbg/start
# Update the state
echo "off" >"$STATE_FILE"
# Turn off leds
echo -n 0 >/sys/class/led_anim/max_scale