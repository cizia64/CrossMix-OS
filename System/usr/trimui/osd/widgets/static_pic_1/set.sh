#!/bin/sh
echo "click:"$1
if [ -f /tmp/trimui_osd/osdd_show_u2 ] ; then
	LD_LIBRARY_PATH=/usr/trimui/lib
	/usr/trimui/bin/mplayer -ao alsa -format s16le -novideo -softvol -softvol-max 100 -volume 100  /mnt/SDCARD/System/usr/trimui/osd/widgets/static_pic_1/abe_fart.wav &
fi
