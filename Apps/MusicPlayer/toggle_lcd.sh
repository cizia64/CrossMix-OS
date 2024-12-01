#!/bin/sh

# File to store the LCD state
STATE_FILE="/tmp/lcd_state"

# Check if the file exists; if not, create it with the "off" state
if [ ! -f "$STATE_FILE" ]; then
  echo "on" >"$STATE_FILE"
fi

# Read the current state
CURRENT_STATE=$(cat "$STATE_FILE")

if [ "$CURRENT_STATE" = "off" ]; then
  # Turn on the LCD
  echo lcd0 >/sys/kernel/debug/dispdbg/name
  echo setbl >/sys/kernel/debug/dispdbg/command
  echo 255 >/sys/kernel/debug/dispdbg/param
  echo 1 >/sys/kernel/debug/dispdbg/start
  # Update the state
  echo "on" >"$STATE_FILE"
  # Turn on leds
  ledset=$(/usr/trimui/bin/shmvar 10)
  scale=$(expr $ledset \* 4)
  echo -n $scale >/sys/class/led_anim/max_scale
else
  # Turn off the LCD
  echo lcd0 >/sys/kernel/debug/dispdbg/name
  echo setbl >/sys/kernel/debug/dispdbg/command
  echo 0 >/sys/kernel/debug/dispdbg/param
  echo 1 >/sys/kernel/debug/dispdbg/start
  # Update the state
  echo "off" >"$STATE_FILE"
  # Turn off leds
  echo -n 0 >/sys/class/led_anim/max_scale
fi
