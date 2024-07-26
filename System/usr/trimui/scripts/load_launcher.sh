#!/usr/bin/env sh

pkill -STOP -f "MainUI" # Pause the MainUI process to get infoscreen.sh working.

export PATH="/mnt/SDCARD/System/usr/trimui/scripts/:/mnt/SDCARD/System/bin:${PATH:+:$PATH}"
export LD_LIBRARY_PATH="/usr/trimui/lib:${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

# find in $1 the parent folder just after Roms/ one
EMU_DIR="$1"
shift
GAME=$(basename "$@")

# Press L to start a game with a saved launcher.
button_state.sh L
[ $? -eq 10 ] && Launcher_name=$(grep -i "$GAME" "$EMU_DIR/presets.txt" | cut -d'=' -f2)

[ -z "$Launcher_name" ] && Launcher_name=$(grep -i default "$EMU_DIR/presets.txt" | cut -d'=' -f2)

# Get the launcher command.
Launcher_command=$(jq -r --arg name "$Launcher_name" \
	'.launchlist[] | select(.name == $name) | .launch' "$EMU_DIR/config.json")

echo "load_launcher.sh : $Launcher_name dowork 0x" >>/tmp/log/messages
"$EMU_DIR"/"$Launcher_command" "$@"
pkill -CONT -f "MainUI"
exit 0
