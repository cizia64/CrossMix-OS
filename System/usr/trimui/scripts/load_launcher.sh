export PATH="/mnt/SDCARD/System/usr/trimui/scripts/:/mnt/SDCARD/System/bin:${PATH:+:$PATH}"
export LD_LIBRARY_PATH="/usr/trimui/lib:${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

EMU_DIR="$(dirname "$0")"
GAME=$(basename "$@")

# Look for a saved preset
if [ -e "$EMU_DIR/presets.txt" ]; then
  # Is there a preset for the game ?
	Launcher_name=$(grep -i "$GAME" "$EMU_DIR/presets.txt" | cut -d'=' -f2)

	if [ -z "$Launcher_name" ]; then
    # else is there a default preset ?
		Launcher_name=$(grep -i default "$EMU_DIR/presets.txt" | cut -d'=' -f2)
	fi

	if [ -n "$Launcher_name" ]; then
		Launcher_command=$(jq -r --arg name "$Launcher_name" \
			'.launchlist[] | select(.name == $name) | .launch' "$EMU_DIR/config.json")
	fi
fi

# If no preset found
if [ -z "$Launcher_name" ]; then
  # Look for the first valid launcher in launchlist
	if jq -e ".launchlist" "$EMU_DIR/config.json" >/dev/null 2>&1; then
		while read launcher; do
			Launcher_name=$(echo "$launcher" | jq -r '.name')
			Launcher_command=$(echo "$launcher" | jq -r '.launch')
			if [ -n "$Launcher_command" ]; then break; fi
		done < <(jq -c '.launchlist[]' "$EMU_DIR/config.json")
	else
    # Else use launch.sh as fallback
		Launcher_name=Unique
		Launcher_command="$EMU_DIR/launch.sh"
	fi
fi

echo "load_launcher.sh : $Launcher_name dowork 0x" >>/tmp/log/messages
"$EMU_DIR/$Launcher_command" "$@"
