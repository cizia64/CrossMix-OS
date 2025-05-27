#!/bin/sh
echo $0 $*
progdir=`dirname "$0"`
cd $progdir
export LD_LIBRARY_PATH=/usr/trimui/lib/
# pkill -f "./com\\."
./fneditor


SCENE_DIR="/usr/trimui/scene"

ps aux | grep "[.]\/com.*[.]sh" | grep "/bin/sh" | while read -r line; do
    pid=$(echo "$line" | awk '{print $1}')
    cmd=$(echo "$line" | grep -o '\./com[^ ]*')

    if [ -n "$cmd" ]; then
        script_name=$(basename "$cmd")
        if [ ! -f "$SCENE_DIR/$script_name" ]; then
            echo "Killing $pid ($script_name), not found in $SCENE_DIR"
            kill "$pid"
        fi
    fi
done