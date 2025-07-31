#!/bin/sh

LIGHT="$1"
[ -z "$LIGHT" ] && exit 1

echo 1 > /sys/class/led_anim/effect_enable
echo 1 > /sys/class/led_anim/effect_cycles_$LIGHT
echo 10 > /sys/class/led_anim/effect_duration_$LIGHT

# Capture + extract dominant color
/mnt/SDCARD/System/bin/fb2png -p /tmp/fb1.png -s8 -t8 -z2 -x320 -y180 -w640 -h360 -s2 -t2 -z2 > /dev/null 2>&1

color=$(/mnt/SDCARD/System/bin/python3.11 /mnt/SDCARD/System/bin/colorthief.py /tmp/fb1.png)

if [ -n "$color" ]; then
    echo "$color" > /sys/class/led_anim/effect_rgb_hex_$LIGHT
    echo 1 > /sys/class/led_anim/effect_$LIGHT
fi
