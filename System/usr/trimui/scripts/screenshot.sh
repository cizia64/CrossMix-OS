#!/bin/sh
FILE=$(date +'%Y%m%d-%Hh%M-%S').png
if [ -f /usr/trimui/osd/show_info_msg.sh ]; then
	/usr/trimui/osd/show_info_msg.sh "$FILE saved." &
fi
/mnt/SDCARD/System/bin/fb2png -p /mnt/SDCARD/Pictures/screenshots/$FILE
