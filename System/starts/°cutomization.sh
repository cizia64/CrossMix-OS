#!/bin/sh
system_json="/mnt/UDISK/system.json"
Current_Theme=$(/usr/trimui/bin/systemval theme)
Current_bg="$Current_Theme/skin/bg.png"
if [ ! -f "$Current_bg" ]; then
	Current_bg="/mnt/SDCARD/trimui/res/skin/transparent.png"
fi

version=$(cat /mnt/SDCARD/System/usr/trimui/crossmix-version.txt)
/mnt/SDCARD/System/bin/sdl2imgshow \
	-i "$Current_bg" \
	-f "/mnt/SDCARD/System/resources/DejaVuSans.ttf" \
	-s 30 \
	-c "220,220,220" \
	-t "CrossMix OS v$version" &
sleep 0.1
pkill -f sdl2imgshow
