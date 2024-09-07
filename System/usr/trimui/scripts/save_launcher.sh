GAME=$(basename "$1")

# Save launcher as default for the game
button_state.sh L
if [ $? -eq 10 ]; then
	Launcher_name=$(grep "dowork 0x" "/tmp/log/messages" | tail -n 1 | sed -e 's/.*: \(.*\) dowork 0x.*/\1/')
	if [ -e "$EMU_DIR/presets.txt" ]; then
		sed -i "/$GAME/d" "$EMU_DIR/presets.txt"
	fi
	echo "$GAME=$Launcher_name" >>"$EMU_DIR/presets.txt"
else
	# Save launcher as default one
	button_state.sh R
	if [ $? -eq 10 ]; then
		Launcher_name=$(grep "dowork 0x" "/tmp/log/messages" | tail -n 1 | sed -e 's/.*: \(.*\) dowork 0x.*/\1/')
		if [ -e "$EMU_DIR/presets.txt" ]; then
			sed -i "s/^default=.*$/default=$Launcher_name/" "$EMU_DIR/presets.txt"
		else
			echo "default=$Launcher_name" >"$EMU_DIR/presets.txt"
		fi
	fi
fi
