#!/bin/sh
export LD_LIBRARY_PATH="/usr/trimui/lib:$LD_LIBRARY_PATH"
PATH="/mnt/SDCARD/System/bin:$PATH"

NightMode=$(/mnt/SDCARD/System/bin/jq -r '.["NightMode"]' "/mnt/SDCARD/System/etc/crossmix.json")

if [ "$NightMode" = "Configurator" ]; then
    # if pgrep -f ra64.trimui >/dev/null; then
        # echo -n "MENU_TOGGLE" | netcat -u -w1 127.0.0.1 55355 &  # problem : RA TrimUI Menu restore day mode
    # fi
    /mnt/SDCARD/System/usr/trimui/scripts/nightmode.sh -night
    if ! pgrep -f nightmode_osdd >/dev/null; then
        cd /mnt/SDCARD/System/usr/trimui/osd/
        ./nightmode_osdd &
    fi
    touch /tmp/show_osd2

elif [ "$NightMode" = "Disabled" ]; then
    echo "NightMode feature disabled in crossmix.json"

    if [ -f /usr/trimui/osd/show_info_msg.sh ]; then
        /usr/trimui/osd/show_default_msg_extra_long.sh "NightMode feature disabled in System Tools"
    fi
else # "$NightMode" = "Toggle" or else
    /mnt/SDCARD/System/usr/trimui/scripts/nightmode.sh
fi

