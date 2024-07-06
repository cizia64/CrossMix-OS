#!/bin/sh
PATH="/mnt/SDCARD/System/bin:$PATH"
LD_LIBRARY_PATH="/mnt/SDCARD/System/lib:/usr/trimui/lib:$LD_LIBRARY_PATH"

/mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "Applying \"$(basename "$0" .sh)\" mode..."

output_file="/mnt/SDCARD/System/etc/led_config.sh"
ScriptName=$(basename "$output_file")

LedLoop() {
    cat <<'EOF'
#!/bin/sh

sleep 2

cpu_speed_file="/sys/devices/system/cpu/cpufreq/policy0/cpuinfo_cur_freq"

set_led_color() {
    r=$1
    g=$2
    b=$3
    valstr=`printf "%02X%02X%02X" $r $g $b`
    echo "$valstr $valstr $valstr $valstr $valstr $valstr $valstr $valstr $valstr $valstr $valstr $valstr $valstr $valstr $valstr $valstr "\
         "$valstr $valstr $valstr $valstr $valstr $valstr $valstr " > /sys/class/led_anim/frame_hex
}


while true; do
    cpu_speed=$(cat $cpu_speed_file)
    cpu_speed=$((cpu_speed / 1000))
	echo $cpu_speed
    if [ $cpu_speed -le 1200 ]; then
        set_led_color 0 255 0  # Green
    elif [ $cpu_speed -le 1300 ]; then
        set_led_color 127 255 0  # Chartreuse Green
    elif [ $cpu_speed -le 1900 ]; then
        set_led_color 255 140 0  # Dark Orange
    elif [ $cpu_speed -le 1991 ]; then
        set_led_color 255 20 0  # Vermilion
    else
        set_led_color 255 0 0  # Red
    fi
    sleep 5
done


EOF
}

echo "====================================== $ScriptName "
LedLoop >"$output_file"
chmod a+x "$output_file"

pkill -f "led_config.sh"
"$output_file" &

# Menu modification to reflect the change immediately

script_name=$(basename "$0" .sh)

json_file="/mnt/SDCARD/System/etc/crossmix.json"
if [ ! -f "$json_file" ]; then
    echo "{}" >"$json_file"
fi
/mnt/SDCARD/System/bin/jq --arg script_name "$script_name" '. += {"LEDS": $script_name}' "$json_file" >"/tmp/json_file.tmp" && mv "/tmp/json_file.tmp" "$json_file"

/mnt/SDCARD/System/usr/trimui/scripts/mainui_state_update.sh "LEDS" "$script_name"
