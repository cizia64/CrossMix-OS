#!/bin/sh

PATH="/mnt/SDCARD/System/usr/trimui/scripts:/mnt/SDCARD/System/bin:$PATH"

varname="cpu_preset"
osd_varname="slider_cpu_preset"
status_file="/tmp/trimui_osd/$osd_varname/status"
curpreset_file="/tmp/trimui_osd/$osd_varname/curpreset"

Min_Value=0
Max_Value=3
interval=1

# Create the folder if necessary
mkdir -p "/tmp/trimui_osd/$osd_varname"

# Retrieving Cur_Value from the status file (before modification)
if [ -f "$status_file" ]; then
    Cur_Value=$(cut -d/ -f1 "$status_file")
else
    Cur_Value=$Min_Value
fi

# Initial mode: Creating the status file on first launch
if [ $# -eq 0 ]; then
    echo "$Cur_Value/$Max_Value" > "$status_file"
    exit 0
fi

# Update the value based on the argument (0 = left, 1 = right)
if [ "$1" -eq 0 ]; then
if [ "$Cur_Value" -eq 1 ]; then
/mnt/SDCARD/System/usr/trimui/scripts/cpufreq-restore.sh &
fi

    Cur_Value=$((Cur_Value - interval))
    [ "$Cur_Value" -lt "$Min_Value" ] && Cur_Value=$Min_Value

elif [ "$1" -eq 1 ]; then

if [ "$Cur_Value" -eq 0 ]; then
/mnt/SDCARD/System/usr/trimui/scripts/cpufreq-save.sh &
fi
    Cur_Value=$((Cur_Value + interval))
    [ "$Cur_Value" -gt "$Max_Value" ] && Cur_Value=$Max_Value
fi

# Updating the status file
echo "$Cur_Value/$Max_Value" > "$status_file"

# Updating the visible frequency (OSD or other use)
case "$Cur_Value" in
    0) 
    Cur_Preset="-"
    ;;
    1) Cur_Preset="low"
    cpufreq.sh powersave 1 3 2
    echo low 
    ;;
    2) Cur_Preset="normal" 
cpufreq.sh ondemand 4 4 4
    ;;
    3) Cur_Preset="performance"
cpufreq.sh performance 6 7 4
    ;;

esac

# ./show_info_msg.sh "Preset: $Cur_Preset"
echo -n "$Cur_Preset" > "$curpreset_file" 