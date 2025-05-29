#!/bin/sh
PATH="/mnt/SDCARD/System/usr/trimui/scripts:/mnt/SDCARD/System/bin:$PATH"

echo "============= scene Night Mode ============"

while true; do
case "$1" in
1)
   
    if [ ! -f "/tmp/nightmode" ]; then
	 
        nightmode.sh -night
		echo "Night mode - enabled"
    fi

    ;;
0)
    
    if [ -f "/tmp/nightmode" ]; then
	if [ ! -f "/tmp/trimui_osd/osdd_show_u2" ]; then
	
        nightmode.sh -day
		echo "Night mode - disabled"
		fi
    fi
    ;;
*) ;;
esac
sleep 1
done