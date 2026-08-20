#!/bin/sh
PATH="/mnt/SDCARD/System/usr/trimui/scripts:/mnt/SDCARD/System/bin:$PATH"

echo "============= toggle CPUFREQ ============"
CPUFREQ_MODE=0

CPUFREQ_MAX=$(cat /sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq)
CPUFREQ_MIN=$(cat /sys/devices/system/cpu/cpufreq/policy0/scaling_min_freq)

echo "cpu scaling freq $CPUFREQ_MIN ~ $CPUFREQ_MAX"

if [ "$CPUFREQ_MIN" -eq 2000000 ] && [ "$CPUFREQ_MAX" -eq 2000000 ]; then
    CPUFREQ_MODE=3

elif [ "$CPUFREQ_MIN" -eq 1608000 ] && [ "$CPUFREQ_MAX" -eq 1800000 ]; then
    CPUFREQ_MODE=2

elif [ "$CPUFREQ_MIN" -eq 1008000 ] && [ "$CPUFREQ_MAX" -eq 1416000 ]; then
    CPUFREQ_MODE=1

elif [ "$CPUFREQ_MIN" -eq 600000 ] && [ "$CPUFREQ_MAX" -eq 1008000 ]; then
    CPUFREQ_MODE=0

else
    echo "Unknown CPU frequency profile: $CPUFREQ_MIN ~ $CPUFREQ_MAX"
    CPUFREQ_MODE=0
fi



##########################################################################

set_led_animation() {
    local color=$1
    local cycles=$2
    local duration=$3
    local effect=${4:-5}
    local target=${5:-lr}   # r / l / lr / f1 / f2 / m / read
    
    case "${color}" in
    red)    color="FF0000" ;;
    green)  color="00FF00" ;;
    blue)   color="0000FF" ;;
    yellow) color="FFFF00" ;;
    orange) color="CC4400" ;;
    esac
    
    
    if [ ! -w "/sys/class/led_anim/effect_enable" ]; then
        chmod a+w /sys/class/led_anim/*
    fi
    
    echo 1 >/sys/class/led_anim/effect_enable
    echo "$color" >/sys/class/led_anim/effect_rgb_hex_${target} 2>/dev/null
    echo "$cycles" >/sys/class/led_anim/effect_cycles_${target} 2>/dev/null
    echo "$duration" >/sys/class/led_anim/effect_duration_${target} 2>/dev/null
    echo "$effect" >/sys/class/led_anim/effect_${target} 2>/dev/null
    
}


led_reset() {
    echo 0 > /sys/class/led_anim/anim_frames_enable
    echo 1 > /sys/class/led_anim/anim_frames_mask_f1f2_enable
    echo 0 > /sys/class/led_anim/anim_frames_mask_lr_enable 
    echo 0 > /sys/class/led_anim/anim_frames_mask_m_enable 
    echo 1 > /sys/class/led_anim/anim_frames_cycles 
}


vibrate_short() {
    echo -n 1 >/sys/class/gpio/gpio227/value
    sleep 0.1
    echo -n 0 >/sys/class/gpio/gpio227/value
}



custom_animation(){
local color=$1
set_led_animation $color 1 10 5 f1
sleep 0.1
set_led_animation $color 2 10 2 f2 &
# vibrate_short &
}


##########################################################################
# switch f2 off
set_led_animation "000000" 1 1 5 f2

case "$CPUFREQ_MODE" in
3 ) 
    echo "set cpufreq mode 1"
    cpufreq.sh powersave 1 3 2
    /usr/trimui/osd/show_info_msg.sh "PowerSave mode"
    custom_animation green &
    ;;
0 ) 
    echo "set cpufreq mode 2"
    cpufreq.sh ondemand 3 5 4
    /usr/trimui/osd/show_info_msg.sh "Balanced mode"
    custom_animation blue &
    ;;
1 ) 
    echo "set cpufreq mode 3"
    cpufreq.sh performance 6 7 4
    /usr/trimui/osd/show_info_msg.sh "Performance mode"
    custom_animation orange &
    ;;
2 ) 
    echo "set cpufreq mode 4"
    cpufreq.sh performance 8 8 4
    /usr/trimui/osd/show_info_msg.sh "Extreme mode"
    custom_animation red &
    ;;
* )
    echo "set cpufreq mode 0"
    cpufreq.sh ondemand 3 5 4
    /usr/trimui/osd/show_info_msg.sh "Balanced mode"
    custom_animation blue &
    ;;
esac


#check again
CPUFREQ_MAX=`cat /sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq`
CPUFREQ_MIN=`cat /sys/devices/system/cpu/cpufreq/policy0/scaling_min_freq`

echo "set cpu scaling freq $CPUFREQ_MIN ~ $CPUFREQ_MAX"
