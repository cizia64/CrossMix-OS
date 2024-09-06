GAME=$(basename "$1")

# Save launcher as default for the game
button_state.sh L
if [ $? -eq 10 ]; then
	Launcher_name=$(grep "dowork 0x" "/tmp/log/messages" | tail -n 1 | sed -e 's/.*: \(.*\) dowork 0x.*/\1/')
	sed -i "/^$GAME/d" presets.txt
	echo "$GAME=$Launcher_name" >>presets.txt
else

	# Save launcher as default one
	button_state.sh R
	if [ $? -eq 10 ]; then
		Launcher_name=$(grep "dowork 0x" "/tmp/log/messages" | tail -n 1 | sed -e 's/.*: \(.*\) dowork 0x.*/\1/')
		if [ ! -f presets.txt ]; then
			touch presets.txt
		else
			sed -i "/^default=/d" presets.txt
		fi
		sed -i "1idefault=$Launcher_name" presets.txt
	fi
fi
