#!/bin/sh
PATH="/mnt/SDCARD/System/bin:$PATH"
LD_LIBRARY_PATH="/mnt/SDCARD/System/lib:/usr/trimui/lib:$LD_LIBRARY_PATH"

/mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "Applying \"$(basename "$0" .sh)\" mode..."

output_file="/mnt/SDCARD/System/etc/led_config.sh"
ScriptName=$(basename "$output_file")

LedLoop() {
    cat <<'EOF'
 sleep 2
#!/bin/sh
cpu_temp_file="/sys/class/thermal/thermal_zone0/temp"
set_led_color() {
    r=$1
    g=$2
    b=$3
    valstr=`printf "%02X%02X%02X" $r $g $b`
    echo "$valstr $valstr $valstr $valstr $valstr $valstr $valstr $valstr $valstr $valstr $valstr $valstr $valstr $valstr $valstr $valstr "\
         "$valstr $valstr $valstr $valstr $valstr $valstr $valstr " > /sys/class/led_anim/frame_hex
}
while true; do
    cpu_temp=$(cat $cpu_temp_file)
    cpu_temp=$((cpu_temp / 1000)) 
    if [ $cpu_temp -le 40 ]; then
        set_led_color 0 255 0  # Green
    elif [ $cpu_temp -le 45 ]; then
        set_led_color 127 255 0  # Chartreuse Green
    elif [ $cpu_temp -le 50 ]; then
        set_led_color 255 255 0  # Yellow
    elif [ $cpu_temp -le 55 ]; then
        set_led_color 255 165 0  # Orange
    elif [ $cpu_temp -le 60 ]; then
        set_led_color 255 140 0  # Dark Orange
    elif [ $cpu_temp -le 65 ]; then
        set_led_color 255 69 0  # Red Orange
    elif [ $cpu_temp -le 70 ]; then
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
