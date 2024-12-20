#!/bin/sh
source /mnt/SDCARD/System/usr/trimui/scripts/common_launcher.sh
source /mnt/SDCARD/System/etc/ex_config

selected_mode=$(grep "dowork 0x" "/tmp/log/messages" | tail -n 1 | sed -e 's/.*: \(.*\) dowork 0x.*/\1/')
case "$selected_mode" in
"High Performance")
	cpufreq.sh performance 2 7
	;;
"Battery Saver")
	cpufreq.sh conservative 2 4
	;;
*)
	cpufreq.sh ondemand 2 6
	;;
esac

if [ -f "/tmp/cmd_to_run.sh" ] && ! grep -q "dowork 0x" "/tmp/cmd_to_run.sh"; then
    sed -i "1s|^|echo \": $selected_mode dowork 0x24a00e60\" > /tmp/log/messages\n|" "/tmp/cmd_to_run.sh"
fi

cd /mnt/SDCARD/Roms/PORTS

################ Fix for TSP controls ################

FILE="$@"
LINE_TO_ADD="sleep 0.6 # For TSP only, do not move/modify this line."

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
