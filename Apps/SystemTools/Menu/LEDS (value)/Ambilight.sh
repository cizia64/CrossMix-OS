#!/bin/sh
PATH="/mnt/SDCARD/System/bin:$PATH"
LD_LIBRARY_PATH="/mnt/SDCARD/System/lib:/usr/trimui/lib:$LD_LIBRARY_PATH"

/mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "Applying \"$(basename "$0")\" by default..."

output_file="/mnt/SDCARD/System/etc/led_config.sh"
ScriptName=$(basename "$output_file")

LedLoop() {
    cat <<'EOF'
sleep 2
#!/bin/sh

echo 1 > /sys/class/led_anim/effect_enable
echo 1 > /sys/class/led_anim/effect_cycles_lr
#echo 100 > /sys/class/led_anim/effect_duration_lr
echo 10 > /sys/class/led_anim/effect_duration_lr


while true; do
    /mnt/SDCARD/System/bin/fb2png -p /tmp/fb1.png -s8 -t8 -z2 -x320 -y180 -w640 -h360 -s2 -t2 -z2
    color=$(/mnt/SDCARD/System/bin/python3.11 /mnt/SDCARD/System/bin/colorthief.py /tmp/fb1.png)
    echo $color > /sys/class/led_anim/effect_rgb_hex_lr
    echo 1 > /sys/class/led_anim/effect_lr
    sleep 0.05
done

EOF
}

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
