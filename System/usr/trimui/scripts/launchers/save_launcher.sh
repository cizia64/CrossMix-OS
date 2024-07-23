GAME=$(basename "$1")

# Save launcher as default for the game
button_state.sh L
if [ $? -eq 10 ]; then
    Launcher_name=$(grep "dowork 0x" "/tmp/log/messages" | tail -n 1 | sed -e 's/.*: \(.*\) dowork 0x.*/\1/')
    sed -i "/$GAME/d" "$PWD/presets.txt"
	echo "$GAME=$Launcher_name" >>"$PWD/presets.txt"
fi

# Save launcher as default one
button_state.sh R
if [ $? -eq 10 ]; then
    Launcher_name=$(grep "dowork 0x" "/tmp/log/messages" | tail -n 1 | sed -e 's/.*: \(.*\) dowork 0x.*/\1/')
    sed -i "s/^default=.*$/default=$Launcher_name/" "$PWD/presets.txt"
fi
