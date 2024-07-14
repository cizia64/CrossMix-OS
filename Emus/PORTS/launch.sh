#!/bin/sh

source /mnt/SDCARD/System/etc/ex_config
EMU_DIR="/mnt/SDCARD/Emus/PORTS"

if grep -i "dowork 0x" "/tmp/log/messages" | tail -n 1 | grep -iq "High Performance"; then
    CPU_PROFILE=performance
elif grep -i "dowork 0x" "/tmp/log/messages" | tail -n 1 | grep -iq "Battery Saver"; then
    CPU_PROFILE=powersave
else
    CPU_PROFILE=balanced
fi

$EMU_DIR/cpufreq.sh "$CPU_PROFILE"

PORTS_DIR=/mnt/SDCARD/Roms/PORTS
cd "$PORTS_DIR"

export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/mnt/SDCARD/System/lib"

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
    ' "$FILE" > /tmp/port_tmp.sh && mv /tmp/port_tmp.sh "$FILE"
fi
sync

######################################################


/bin/sh "$@"