export PATH="/mnt/SDCARD/System/usr/trimui/scripts/:/mnt/SDCARD/System/bin:${PATH:+:$PATH}"
export LD_LIBRARY_PATH="/usr/trimui/lib:${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

EMU_DIR="$(dirname "$0")"
GAME=$(basename "$@")

# The preset file is only created after a first saved launcher.
if [ -e "$EMU_DIR/presets.txt" ]; then
	# Press L to start a game with a saved launcher.
	button_state.sh L
	[ $? -eq 10 ] && Launcher_name=$(grep -i "$GAME" "$EMU_DIR/presets.txt" | cut -d'=' -f2)

	[ -z "$Launcher_name" ] && Launcher_name=$(grep -i default "$EMU_DIR/presets.txt" | cut -d'=' -f2)
	Launcher_command=$(jq -r --arg name "$Launcher_name" \
		'.launchlist[] | select(.name == $name) | .launch' "$EMU_DIR/config.json")
elif jq -e ".launchlist" "$EMU_DIR/config.json" > /dev/null 2>&1; then
# So if it not yet created, search for the first valid launcher.
	while read launcher; do
		Launcher_name=$(echo "$launcher" | jq -r '.name')
		Launcher_command=$(echo "$launcher" | jq -r '.launch')
		if [ -n "$Launcher_command" ]; then break; fi
	done < <(jq -c '.launchlist[]' "$EMU_DIR/config.json")
else
  Launcher_name=Unique
  Launcher_command="$EMU_DIR/launch.sh"
fi

echo "load_launcher.sh : $Launcher_name dowork 0x" >>/tmp/log/messages
"$EMU_DIR/$Launcher_command" "$@"
