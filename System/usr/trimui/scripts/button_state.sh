#!/bin/sh

# ======================================================
# Examples of use:
# ======================================================
# button_state.sh MENU || echo "Button MENU pressed"
# button_state.sh MENU && echo "Button MENU not pressed"
# ======================================================
# ./button_state.sh A
# exit_code=$?
# if [ $exit_code -eq 10 ]; then
    # echo "The button is currently pressed."
# elif [ $exit_code -eq 0 ]; then
    # echo "The button is currently released."
# else
    # echo "Error determining button state."
# fi
# ======================================================

if [ "$#" -lt 1 ]; then
    echo "Usage: $0 [BUTTON]"
    echo "Example: $0 A"
    exit 1
fi

BUTTON="$1"

# Input device location
DEVICE_PATH="/dev/input/event3"

# Button mapping table
case $BUTTON in
    A) EVENT_TYPE="1" ; EVENT_CODE="305" ;;
    B) EVENT_TYPE="1" ; EVENT_CODE="304" ;;
    X) EVENT_TYPE="1" ; EVENT_CODE="308" ;;
    Y) EVENT_TYPE="1" ; EVENT_CODE="307" ;;
    L) EVENT_TYPE="1" ; EVENT_CODE="310" ;;
    R) EVENT_TYPE="1" ; EVENT_CODE="311" ;;
    SELECT) EVENT_TYPE="1" ; EVENT_CODE="314" ;;
    START) EVENT_TYPE="1" ; EVENT_CODE="315" ;;
    MENU) EVENT_TYPE="1" ; EVENT_CODE="316" ;;
    FN) EVENT_TYPE="5" ; EVENT_CODE="1" ;;
    *) echo "Button not found"; exit 1 ;;
esac

# Debug: Display the corresponding button
echo "Button: $BUTTON"

# Use evtest --query to query the current state of the button
/mnt/SDCARD/System/usr/trimui/scripts/evtest --query "$DEVICE_PATH" "$EVENT_TYPE" "$EVENT_CODE"

# Store the exit code of evtest
exit_code=$?

# Check the exit code and display an appropriate message
if [ $exit_code -eq 10 ]; then
    echo "$BUTTON is currently active."
elif [ $exit_code -eq 0 ]; then
    echo "$BUTTON is currently inactive."
else
    echo "Error querying $BUTTON."
fi

exit $exit_code
