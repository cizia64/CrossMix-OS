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

	/mnt/SDCARD/System/usr/trimui/scripts/nightmode_launcher.sh osd

fi
