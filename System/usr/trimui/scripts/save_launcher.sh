#!/usr/bin/env sh

export PATH="/mnt/SDCARD/System/usr/trimui/scripts/:/mnt/SDCARD/System/bin:${PATH:+:$PATH}"
export LD_LIBRARY_PATH="/usr/trimui/lib:${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

EMU_DIR="$1"
GAME=$(basename "$2")

# Save launcher as default for the game
button_state.sh L
if [ $? -eq 10 ]; then
    Launcher_name=$(grep "dowork 0x" "/tmp/log/messages" | tail -n 1 | sed -e 's/.*: \(.*\) dowork 0x.*/\1/')
    sed -i "/$GAME/d" "$EMU_DIR/presets.txt"
	echo "$GAME=$Launcher_name" >>"$EMU_DIR/presets.txt"
fi

# Save launcher as default one
button_state.sh R
if [ $? -eq 10 ]; then
    Launcher_name=$(grep "dowork 0x" "/tmp/log/messages" | tail -n 1 | sed -e 's/.*: \(.*\) dowork 0x.*/\1/')
    sed -i "s/^default=.*$/default=$Launcher_name/" "$EMU_DIR/presets.txt"
fi
