#!/bin/sh

# This script monitors input events. If specific button names are provided as arguments,
# the script will only print and exit if one of those buttons is detected. If no 
# arguments are provided, the script will print and exit upon detecting any valid button.

# Usage:
#   ./script_name.sh [BUTTON1 BUTTON2 ...]
# Examples:
#   ./script_name.sh           # Monitors and prints any button detected
#   ./script_name.sh A B START # Only prints and exits if A, B, or START is detected



# Input device location
DEVICE_PATH="/dev/input/event3"

# Button mapping table
map_button() {
    case "$1" in
        305) echo "A" ;;
        304) echo "B" ;;
        307) echo "Y" ;;
        308) echo "X" ;;
        310) echo "L" ;;
        311) echo "R" ;;
        314) echo "SELECT" ;;
        315) echo "START" ;;
        316) echo "MENU" ;;
        1)   echo "FN" ;;
        17:-1) echo "UP" ;;
        17:1)  echo "DOWN" ;;
        16:-1) echo "LEFT" ;;
        16:1)  echo "RIGHT" ;;
        1:1)   echo "FN_RIGHT" ;;
        1:0)   echo "FN_LEFT" ;;
        *)     echo "" ;;
    esac
}

# Convert script arguments to a set of valid buttons if any are provided
if [ "$#" -gt 0 ]; then
    VALID_BUTTONS=$(printf "%s\n" "$@" | tr ' ' '\n' | sort -u)
else
    VALID_BUTTONS=""
fi

# Start evtest and parse its output
/mnt/SDCARD/System/usr/trimui/scripts/evtest "$DEVICE_PATH" | while read -r line; do
    # Check if the line contains an EV_KEY, EV_ABS, or EV_SW event
    echo "$line" | grep -E "EV_KEY|EV_ABS|EV_SW" > /dev/null
    if [ $? -eq 0 ]; then
        # Extract the event type, code, and value from the line
        EVENT_TYPE=$(echo "$line" | awk '{print $6}')
        EVENT_CODE=$(echo "$line" | awk '{print $8}')
        EVENT_VALUE=$(echo "$line" | awk '{print $NF}')

        # Validate that EVENT_CODE and EVENT_VALUE are numbers before proceeding
        if echo "$EVENT_CODE" | grep -Eq '^[0-9]+$' && echo "$EVENT_VALUE" | grep -Eq '^-?[0-9]+$'; then
            # Check if the key was pressed (value 1) or the relevant ABS/SW event occurred
            if [ "$EVENT_TYPE" = "(EV_KEY)," ] && [ "$EVENT_VALUE" -eq 1 ]; then
                BUTTON=$(map_button "$EVENT_CODE")
            elif [ "$EVENT_TYPE" = "(EV_ABS)," ]; then
                BUTTON=$(map_button "$EVENT_CODE:$EVENT_VALUE")
            elif [ "$EVENT_TYPE" = "(EV_SW)," ]; then
                BUTTON=$(map_button "$EVENT_CODE:$EVENT_VALUE")
            else
                BUTTON=""
            fi

            if [ -n "$BUTTON" ]; then
                if [ -z "$VALID_BUTTONS" ] || echo "$VALID_BUTTONS" | grep -q "^$BUTTON$"; then
                    echo "$BUTTON"
					pkill -9 evtest  # avoid no exit problem when launched from MainUI
                    exit
                fi
            fi
        fi
    fi
done
