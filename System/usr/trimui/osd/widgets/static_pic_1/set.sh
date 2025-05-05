#!/bin/sh
echo "click:"$1
if [ -f /tmp/trimui_osd/osdd_show_u2 ]; then
	aplay $(pwd)/widgets/static_pic_1/abe_fart.wav &
fi
