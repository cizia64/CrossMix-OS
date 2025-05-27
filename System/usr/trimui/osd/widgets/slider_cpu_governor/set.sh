#!/bin/sh
# echo $*  # args (only one: 0 left, 1 right)
# echo $#  # number of args
PATH="/mnt/SDCARD/System/usr/trimui/scripts:/mnt/SDCARD/System/bin:$PATH"

varname="cpu_governor"
osd_varname="slider_cpu_governor"

# Mapping: index <-> governor
governors="powersave conservative userspace schedutil interactive ondemand performance"
governor=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)



# here set the value:
# Index	Governor	Description
# 0	powersave	Always uses the lowest possible CPU frequency to save power.
# 1	conservative	Gradually increases frequency under load — good balance between power saving and responsiveness.
# 2	userspace	Allows user or scripts to set CPU frequency manually.
# 3	schedutil	Dynamically adjusts frequency based on the Linux scheduler's activity — modern and efficient.
# 4	interactive	Quickly ramps up frequency on user interaction, then lowers it slowly — ideal for UI smoothness.
# 5	ondemand	Aggressively increases frequency under load, and drops it quickly when idle.
# 6	performance	Keeps the CPU running at the highest possible frequency at all times — maximum performance.



# Determine current index based on current governor
i=0
for g in $governors; do
    if [ "$g" = "$governor" ]; then
        Cur_Value=$i
        break
    fi
    i=$((i + 1))
done

Min_Value=0
Max_Value=6
interval=1

if [ $# -eq 0 ]; then # at OSD loading
    mkdir -p /tmp/trimui_osd/$osd_varname/
    echo "$Cur_Value/$Max_Value" >/tmp/trimui_osd/$osd_varname/status
    exit
fi



# Handle slider direction
if [ "$1" -eq 0 ]; then
    Cur_Value=$((Cur_Value - interval))
    [ "$Cur_Value" -lt "$Min_Value" ] && Cur_Value=$Min_Value
elif [ "$1" -eq 1 ]; then
    Cur_Value=$((Cur_Value + interval))
    [ "$Cur_Value" -gt "$Max_Value" ] && Cur_Value=$Max_Value
fi

# Apply new governor
i=0
for g in $governors; do
    if [ "$i" -eq "$Cur_Value" ]; then
        for cpu in /sys/devices/system/cpu/cpu[0-9]*; do
            echo "$g" > "$cpu/cpufreq/scaling_governor" 2>/dev/null
        done
        break
    fi
    i=$((i + 1))
done

# Update slider
mkdir -p /tmp/trimui_osd/$osd_varname/
echo "$Cur_Value/$Max_Value" >/tmp/trimui_osd/$osd_varname/status

./show_info_msg.sh "Governor: $g"
