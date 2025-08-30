#!/bin/sh
echo "$0" "$*"

export PATH="/mnt/SDCARD/System/usr/trimui/scripts/:/mnt/SDCARD/System/bin:$PM_DIR:${PATH:+:$PATH}"
export LD_LIBRARY_PATH="/usr/trimui/lib:/mnt/SDCARD/System/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

# Switch audio and set hotkey
ra_audio_switcher.sh
touch /var/trimui_inputd/ra_hotkey

RA_DIR=/mnt/SDCARD/RetroArch
cd "$RA_DIR"

/mnt/SDCARD/System/usr/trimui/scripts/button_state.sh Y
if [ $? -eq 10 ]; then
    FILE_LIST=""
    for f in "$RA_DIR"/ra64.trimui*; do
        # Add each filename, quoted to protect spaces
        FILE_LIST="$FILE_LIST '$(basename "$f")' "
    done

    # Use eval to pass properly to selector
    SELECTED_FILE=$(eval /mnt/SDCARD/System/bin/selector -fs 120 -c $FILE_LIST)
    SELECTED_FILE=$(printf '%s\n' "$SELECTED_FILE" | sed 's/^.*: //')
fi

if [ -z "$SELECTED_FILE" ]; then
    SELECTED_FILE="ra64.trimui"
fi

HOME="$RA_DIR/" "$RA_DIR/$SELECTED_FILE"
