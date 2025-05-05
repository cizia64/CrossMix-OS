#!/bin/sh
# echo $*
# echo $#
PATH="/mnt/SDCARD/System/usr/trimui/scripts:/mnt/SDCARD/System/bin:$PATH"

source /mnt/SDCARD/System/etc/nightmode.conf
varname="enhance_saturation"
osd_varname="slider_saturation"
Cur_Value=$enhance_saturation

Min_Value=0
Max_Value=100
interval=10

# Cur_Value=$(cat /sys/class/disp/disp/attr/color_temperature)
if [ $# -eq 0 ]; then # at OSD loading
    mkdir -p /tmp/trimui_osd/$osd_varname/
    echo "$Cur_Value/$Max_Value" >/tmp/trimui_osd/$osd_varname/status
    exit
fi

if [ ! -f "/tmp/nightmode" ]; then
    ./show_info_msg.sh "Go back to night mode."
    nightmode.sh -night
fi

if [ $1 -eq 0 ]; then
    Cur_Value=$((Cur_Value - $interval))
    if [ $Cur_Value -lt $Min_Value ]; then
        Cur_Value=$Min_Value
    fi

elif [ $1 -eq 1 ]; then
    Cur_Value=$((Cur_Value + $interval))
    if [ $Cur_Value -gt $Max_Value ]; then
        Cur_Value=$Max_Value
    fi
fi

echo "$Cur_Value/$Max_Value" >/tmp/trimui_osd/$osd_varname/status
nightmode.sh -set $varname $Cur_Value
