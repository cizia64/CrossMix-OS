if [ $# -eq 0 ] ; then
    value=`/usr/trimui/bin/shmvar brightness`
    mkdir -p /tmp/trimui_osd/slider_backlight/
    echo "$value/10" > /tmp/trimui_osd/slider_backlight/status
else
    if [ $1 -eq 0 ] ; then
        value=`/usr/trimui/bin/shmvar brightness`
        value=$((value-1))
        if [ $value -lt 0 ] ; then
            value=0
        fi
        echo $value > /tmp/system/set_brightness
        echo "$value/10" > /tmp/trimui_osd/slider_backlight/status
    elif [ $1 -eq 1 ] ; then
        value=`/usr/trimui/bin/shmvar brightness`
        value=$((value+1))
        if [ $value -gt 10 ] ; then
            value=10
        fi
        echo $value > /tmp/system/set_brightness
        echo "$value/10" > /tmp/trimui_osd/slider_backlight/status
    fi
fi
