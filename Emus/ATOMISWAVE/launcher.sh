#!/usr/bin/env sh

export PATH="/mnt/SDCARD/System/usr/trimui/scripts/${PATH:+:$PATH}"
EMU_DIR=$(dirname "$0")
GAME=$(basename "$1")

# Check if the user started holding L2
button_state.sh L2
if [ $? -eq 10 ]; then
    # Search for a game saved launcher.
	Game_launcher=$(grep -i "$GAME" "$EMU_DIR/presets.txt" | cut -d'=' -f2)

    # Set a new saved launcher.
	if [ -z "$Game_launcher" ]; then
		pipe=/tmp/launcher.fifo
		mkfifo $pipe

		i=1

		for file in launch_*.sh; do
			echo "echo \"$i: $file\"" >>$pipe
            i=$((i + 1))
		done
		(
			cat <<'EOF'
echo -e "\tSelect the launcher you want to use:"
read -r tmp
echo "$tmp" >/tmp/launcher.fifo
exit
EOF
		) >>$pipe &

		/mnt/SDCARD/Apps/Terminal/SimpleTerminal -e "sh /tmp/launcher.fifo"

        # Recuperate the selected launcher from fifo.
		select=$(cat /tmp/launcher.fifo)
        rm -f /tmp/launcher.fifo

		Game_launcher=$(ls launch_*.sh | sed -n "$select p")
		echo "$GAME=$Game_launcher" >>"$EMU_DIR/presets.txt"
	fi
    # Start game's launcher
	"$EMU_DIR"/"$Game_launcher" "$GAME"
	exit 0
fi

# Start default launcher.
$(grep -i default "$EMU_DIR/presets.txt" | cut -d'=' -f2) "$GAME"
exit 0
