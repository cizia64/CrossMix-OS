if [ $# -eq 0 ] ; then
    value=`/usr/trimui/bin/shmvar vol`
    mkdir -p /tmp/trimui_osd/slider_volume/
    echo "$value/20" > /tmp/trimui_osd/slider_volume/status
else
    if [ $1 -eq 0 ] ; then
        value=`/usr/trimui/bin/shmvar vol`
        value=$((value-1))
        if [ $value -lt 0 ] ; then
            value=0
        fi
        echo $value > /tmp/system/set_volume
        echo "$((value-1))/19" > /tmp/trimui_osd/slider_volume/status        
    elif [ $1 -eq 1 ] ; then
        value=`/usr/trimui/bin/shmvar vol`
        value=$((value+1))
        if [ $value -gt 20 ] ; then
            value=20
        fi
        echo $value > /tmp/system/set_volume
        echo "$((value-1))/19" > /tmp/trimui_osd/slider_volume/status
    fi
fi