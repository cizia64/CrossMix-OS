#!/bin/sh
PATH="/mnt/SDCARD/System/usr/trimui/scripts:/mnt/SDCARD/System/bin:$PATH"

varname="cpu_minfreq"
osd_varname="slider_cpu_minfreq"

frequencies="408000 600000 816000 1008000 1200000 1416000 1608000 1800000 2000000"
Min_Value=0
Max_Value=8
interval=1

current=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq)
i=0
for f in $frequencies; do
    if [ "$f" = "$current" ]; then
        Cur_Value=$i
        break
    fi
    i=$((i + 1))
done

if [ $# -eq 0 ]; then
    mkdir -p /tmp/trimui_osd/$osd_varname/
    echo "$Cur_Value/$Max_Value" > /tmp/trimui_osd/$osd_varname/status
    exit
fi

if [ "$1" -eq 0 ]; then
    Cur_Value=$((Cur_Value - interval))
    [ "$Cur_Value" -lt "$Min_Value" ] && Cur_Value=$Min_Value
elif [ "$1" -eq 1 ]; then
    Cur_Value=$((Cur_Value + interval))
    [ "$Cur_Value" -gt "$Max_Value" ] && Cur_Value=$Max_Value
fi

# Apply min freq (only if <= current max freq)
i=0
for f in $frequencies; do
    if [ "$i" -eq "$Cur_Value" ]; then
        maxf=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq)
        if [ "$f" -gt "$maxf" ]; then
            ./show_info_msg_extra_long.sh "Min > Max! Cancelled. (Stay at $((f / 1000)) MHz)"
        else
            echo "$f" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq
            ./show_info_msg.sh "Min freq: $((f / 1000)) MHz"
        fi
        break
    fi
    i=$((i + 1))
done

echo "$Cur_Value/$Max_Value" > /tmp/trimui_osd/$osd_varname/status
