GAME=$(basename "$1")

save_launcher() {
	[ -z "$1" ] && set default

	Launcher_name=$(grep "dowork 0x" "/tmp/log/messages" | tail -n 1 | sed -e 's/.*: \(.*\) dowork 0x.*/\1/')

	if [ ! -f presets.txt ]; then
		echo "$1=$Launcher_name" >presets.txt
	elif grep -q "^$1=" presets.txt &>/dev/null; then
		sed -i "s/^$1=.*/$1=$Launcher_name/" presets.txt
	elif [ "$1" = default ]; then
		sed -i "1idefault=$Launcher_name" presets.txt
	else
		echo "$1=$Launcher_name" >>presets.txt
	fi
}

button_state.sh L
[ $? -eq 10 ] && save_launcher "$GAME"

# Save launcher as default one
button_state.sh R
[ $? -eq 10 ] && save_launcher
