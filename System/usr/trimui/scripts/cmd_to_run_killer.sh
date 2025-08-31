#!/bin/sh

# Usage: ./kill_tree.sh <timeout_seconds>
# Example: ./kill_tree.sh 5

TIMEOUT="${1:-3}"         # Seconds before escalating to SIGKILL (default 3s)
CHECK_INTERVAL=0.2        # Polling interval
KILL_LIST=""

# Recursively collect child PIDs in post-order (children first, parent last)
collect_kill_list() {
    local pid=$1
    local children=$(ps -e -o pid= -o ppid= | awk -v p="$pid" '$2 == p { print $1 }')
    
    for child in $children; do
        collect_kill_list "$child"
    done
    
    KILL_LIST="$KILL_LIST $pid"
}

# Attempt clean shutdown of RetroArch if it's running (ra64.trimui)
try_clean_retroarch_exit() {
    local ra_pid
    ra_pid=$(pgrep -f ra64.trimui)
    
    if [ -n "$ra_pid" ]; then
        
        echo "Detected RetroArch (PID $ra_pid), attempting clean shutdown..."
        echo -n "QUIT" | /mnt/SDCARD/System/bin/netcat -u -w1 127.0.0.1 55355
        echo -n "QUIT" | /mnt/SDCARD/System/bin/netcat -u -w1 127.0.0.1 55355
        
        sleep 0.5
        # If the TrimUI Game Menu is detected, we exit it to allow RetroArch to close properly
        state_code=$(sed -n 's/^State:[ \t]*\([A-Z]\).*/\1/p' /proc/"$ra_pid"/status)
        if [ "$state_code" = "S" ]; then
            echo "TrimUI ingame menu detected"
            /mnt/SDCARD/System/bin/sendkey /dev/input/event3 B 2
            sleep 3
        fi
        
        elapsed=0
        while kill -0 "$ra_pid" 2>/dev/null; do
            sleep "$CHECK_INTERVAL"
            elapsed=$(echo "$elapsed + $CHECK_INTERVAL" | bc)
            if [ "$(echo "$elapsed >= $TIMEOUT" | bc)" -eq 1 ]; then
                echo "RetroArch still running after $TIMEOUT s, sending SIGKILL"
                kill -9 "$ra_pid"
                break
            fi
        done
        
        if ! kill -0 "$ra_pid" 2>/dev/null; then
            echo "RetroArch terminated cleanly."
        fi
    fi
}

# Try to terminate a PID, escalate to SIGKILL if needed
terminate_pid() {
    local pid=$1
    kill "$pid"
    echo "sigterm sent to $pid"
    
    elapsed=0
    while kill -0 "$pid" 2>/dev/null; do
        sleep "$CHECK_INTERVAL"
        elapsed=$(echo "$elapsed + $CHECK_INTERVAL" | bc)
        if [ "$(echo "$elapsed >= $TIMEOUT" | bc)" -eq 1 ]; then
            echo "Process $pid still alive after $TIMEOUT s, sending SIGKILL"
            kill -9 "$pid"
            break
        fi
    done
}

# Try to shut down RetroArch cleanly if running
try_clean_retroarch_exit

# Find the parent process
PARENT_PID=$(pgrep -f "cmd_to_run.sh")
if [ -n "$PARENT_PID" ]; then
    echo "Found parent process: $PARENT_PID"
    
    collect_kill_list "$PARENT_PID"
    
    for pid in $KILL_LIST; do
        echo "Terminating $pid"
        terminate_pid "$pid"
    done
else
    echo "No matching process found."
fi



