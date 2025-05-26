#!/bin/sh
PATH="/mnt/SDCARD/System/usr/trimui/scripts:/mnt/SDCARD/System/bin:$PATH"

varname="cpu_active"
osd_varname="slider_cpu_active"

Min_Value=1
Max_Value=4
interval=1
Slider_Min=0
Slider_Max=3  # 1 CPU = slider 0, 4 CPUs = slider 3

# Detect current number of active cores (cpu0 always counted)
Cur_Value=0
for cpu in /sys/devices/system/cpu/cpu[0-9]*; do
    i=$(basename "$cpu" | sed 's/cpu//')
    if [ "$i" -eq 0 ]; then
        Cur_Value=$((Cur_Value + 1))
        continue
    fi
    if [ -f "$cpu/online" ]; then
        if [ "$(cat "$cpu/online")" -eq 1 ]; then
            Cur_Value=$((Cur_Value + 1))
        fi
    fi
done

# Convert to slider value (0-based)
Slider_Value=$((Cur_Value - 1))

if [ $# -eq 0 ]; then
    mkdir -p /tmp/trimui_osd/$osd_varname/
    echo "$Slider_Value/$Slider_Max" > /tmp/trimui_osd/$osd_varname/status
    exit
fi

# Slider movement
if [ "$1" -eq 0 ]; then
    Slider_Value=$((Slider_Value - interval))
    [ "$Slider_Value" -lt "$Slider_Min" ] && Slider_Value=$Slider_Min
elif [ "$1" -eq 1 ]; then
    Slider_Value=$((Slider_Value + interval))
    [ "$Slider_Value" -gt "$Slider_Max" ] && Slider_Value=$Slider_Max
fi

# Convert back to number of active CPUs
Cur_Value=$((Slider_Value + 1))

# Apply core state (only cpu0..cpu3)
for cpu in /sys/devices/system/cpu/cpu[0-9]*; do
    i=$(basename "$cpu" | sed 's/cpu//')
    [ "$i" -gt 3 ] && continue  # only cpu0..cpu3
    if [ "$i" -eq 0 ]; then
        continue  # cpu0 always active
    fi
    if [ -f "$cpu/online" ]; then
        if [ "$i" -lt "$Cur_Value" ]; then
            echo 1 > "$cpu/online"
        else
            echo 0 > "$cpu/online"
        fi
    fi
done

./show_info_msg.sh "Active cores: $Cur_Value"
echo "$Slider_Value/$Slider_Max" > /tmp/trimui_osd/$osd_varname/status
