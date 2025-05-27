MODE_FILE="/tmp/nightmode"
if [ ! -f "$MODE_FILE" ]; then
	echo 0 >/tmp/trimui_osd/toggle_nightmode/status
else
	echo 1 >/tmp/trimui_osd/toggle_nightmode/status
fi
