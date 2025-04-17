#!/bin/sh

# File to store the LCD state
STATE_FILE="/tmp/lcd_state"

# Check if the file exists; if not, create it with the "on" state
if [ ! -f "$STATE_FILE" ]; then
  echo "on" >"$STATE_FILE"
fi

# Read the current state
CURRENT_STATE=$(cat "$STATE_FILE")

if [ "$CURRENT_STATE" = "off" ]; then
  ./lcd_on.sh
else
  ./lcd_off.sh
fi