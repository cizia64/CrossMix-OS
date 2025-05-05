#!/bin/sh
# echo $*
# echo $#
PATH="/mnt/SDCARD/System/usr/trimui/scripts:/mnt/SDCARD/System/bin:$PATH"

MODE_FILE="/tmp/nightmode"
if [ ! -f "$MODE_FILE" ]; then
	value=0
else
	value=1
fi

if [ $# -eq 0 ]; then

	mkdir -p /tmp/trimui_osd/toggle_nightmode/
	echo $value >/tmp/trimui_osd/toggle_nightmode/status

else

	if [ $value -eq 1 ]; then

		nightmode.sh -day
		echo 0 >/tmp/trimui_osd/toggle_nightmode/status

	elif [ $value -eq 0 ]; then

		nightmode.sh -night
		echo 1 >/tmp/trimui_osd/toggle_nightmode/status

	fi
fi
