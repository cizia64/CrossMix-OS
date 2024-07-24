#!/usr/bin/env sh

pkill -STOP -f "MainUI" # Pause the MainUI process to get infoscreen.sh working.

export PATH="/mnt/SDCARD/System/usr/trimui/scripts/:/mnt/SDCARD/System/bin:${PATH:+:$PATH}"
export LD_LIBRARY_PATH="/usr/trimui/lib:${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
EMU_DIR=$(dirname "$0")
GAME=$(basename "$1")

select_launcher() {
	i=-1
	button=$(infoscreen.sh -k "A B L R" -fs 18 -m "Select the launcher you want to use. Press A to select, B to cancel, L1 to go to the previous launcher and R1 to go to the next launcher.")
	while :; do
		case $button in
		A)
			name=$(jq -r ".launchlist[$i].name" "$EMU_DIR/config.json")
			echo "$name"
			return
			;;
		B)
			pkill -CONT -f "MainUI"
			exit 0
			;;
		L)
			i=$((i - 1))
			[ $i -lt 0 ] && i=$(jq '.launchlist | length - 1' "$EMU_DIR/config.json")
			;;
		R)
			i=$((i + 1))
			[ $i -ge "$(jq '.launchlist | length' "$EMU_DIR/config.json")" ] && i=0
			;;
		esac
		name=$(jq -r ".launchlist[$i].name" "$EMU_DIR/config.json")
		launch=$(jq -r ".launchlist[$i].launch" "$EMU_DIR/config.json")
		# Skip titles and separators.
		if [ -z "$launch" ]; then
			continue
		fi
		# Display the actual launcher name and get the user input.
		button=$(infoscreen.sh -k "A B L R" -fs 18 -m "Launcher: $name")
	done
}

# Press R to set a new game's default launcher.
button_state.sh R
if [ $? -eq 10 ]; then
	Launcher_name=$(select_launcher)
    sed -i "/$GAME/d" "$EMU_DIR/presets.txt"
	echo "$GAME=$Launcher_name" >>"$EMU_DIR/presets.txt"
else
	# Press L to start a game with a saved launcher.
	button_state.sh L
	if [ $? -eq 10 ]; then

		# Search for a game saved launcher.
		Launcher_name=$(grep -i "$GAME" "$EMU_DIR/presets.txt" | cut -d'=' -f2)

		# If the game's launcher is not saved, select a new one.
		if [ -z "$Launcher_name" ]; then
			Launcher_name=$(select_launcher)
			echo "$GAME=$Launcher_name" >>"$EMU_DIR/presets.txt"
		fi
	else # Default launcher.
		Launcher_name=$(grep -i default "$EMU_DIR/presets.txt" | cut -d'=' -f2)
	fi
fi
# Get the launcher command.
Launcher_command=$(jq -r --arg name "$Launcher_name" '.launchlist[] | select(.name == $name) | .launch' "$EMU_DIR/config.json")
echo "dowork 0x $Launcher_name" >> /tmp/log/messages
"$EMU_DIR"/"$Launcher_command" "$@"
pkill -CONT -f "MainUI"
exit 0
