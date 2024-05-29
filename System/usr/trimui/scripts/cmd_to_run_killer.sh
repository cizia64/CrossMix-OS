#!/bin/sh

find_children() {
    local parent_pid=$1
    local children=$(ps -e -o pid,ppid | awk -v pid="$parent_pid" '$2 == pid { print $1 }')

    for child_pid in $children; do
        echo "$child_pid"
        find_children "$child_pid"
    done
	
	kill $child_pid
	sleep 3
	if kill -0 "$PID" 2>/dev/null; then
	kill -9 $child_pid
	fi
}


PARENT_PID=$(pgrep -f "cmd_to_run.sh")
if [ -n "$PARENT_PID" ]; then
    echo "Processus parent : $PARENT_PID"
    find_children "$PARENT_PID"
else
    echo "No matching process found."
fi
