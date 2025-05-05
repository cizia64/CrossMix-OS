#!/bin/sh
# echo $*
# echo $#
PATH="/mnt/SDCARD/System/usr/trimui/scripts:/mnt/SDCARD/System/bin:$PATH"

if [ -f /tmp/trimui_osd/osdd_show_u2 ]; then # no run at launch , only when the osd is currently displayed
	nightmode.sh -day                           # generate backup of day settings again
	rm /mnt/SDCARD/System/etc/nightmode.conf
	sync
	nightmode.sh -night

	# Refresh sliders values
	./widgets/slider_backlight/set.sh
	./widgets/slider_brightness/set.sh
	./widgets/slider_color_temperature/set.sh
	./widgets/slider_contrast/set.sh
	./widgets/slider_saturation/set.sh
fi
