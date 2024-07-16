#!/bin/sh

source /mnt/SDCARD/System/etc/ex_config
EMU_DIR="/mnt/SDCARD/Emus/PORTS"

selected_option=$(grep "dowork 0x" "/tmp/log/messages" | tail -n 1 | sed -e 's/.*: \(.*\) dowork 0x.*/\1/')

$EMU_DIR/cpufreq.sh "$selected_option"

PORTS_DIR=/mnt/SDCARD/Roms/PORTS
cd "$PORTS_DIR"

################ Fix for TSP controls ################

FILE="$@"
LINE_TO_ADD="sleep 0.3 # For TSP only, do not move/modify this line."

# Check if the line already exists
if ! grep -q "$LINE_TO_ADD" "$FILE"; then
    # Use awk to insert the line after the target line only if it doesn't already exist
    awk -v line="$LINE_TO_ADD" '
    BEGIN { line_inserted = 0 }
    /^[[:space:]]*\$GPTOKEYB[[:space:]]*.*&[[:space:]]*$/ {
        print $0
        if (!line_inserted) {
            print line
            line_inserted = 1
        }
        next
    }
    { print $0 }
    ' "$FILE" >/tmp/port_tmp.sh && mv /tmp/port_tmp.sh "$FILE"
fi
sync

######################################################

export LD_LIBRARY_PATH="/mnt/SDCARD/System/lib:$LD_LIBRARY_PATH"
/bin/sh "$@"
