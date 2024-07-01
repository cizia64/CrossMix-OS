#!/bin/sh
PATH="/mnt/SDCARD/System/bin:$PATH"
LD_LIBRARY_PATH="/mnt/SDCARD/System/lib:/usr/trimui/lib:$LD_LIBRARY_PATH"

/mnt/SDCARD/System/bin/sdl2imgshow \
    -i "/mnt/SDCARD/trimui/res/crossmix-os/bg-info.png" \
    -f "/mnt/SDCARD/System/resources/DejaVuSans.ttf" \
    -s 50 \
    -c "220,220,220" \
    -t "Applying \"$(basename "$0" .sh)\" mode..." &

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
    /mnt/SDCARD/bin/fb2png -p /tmp/fb1.png -s8 -t8 -z2 -x320 -y180 -w640 -h360 -s2 -t2 -z2
    color=$(/mnt/SDCARD/System/bin/python3.11 /mnt/SDCARD/bin/colorthief.py /tmp/fb1.png)
    echo $color > /sys/class/led_anim/effect_rgb_hex_lr
    echo 1 > /sys/class/led_anim/effect_lr
    sleep 0.05
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

database_file="/mnt/SDCARD/Apps/SystemTools/Menu/Menu_cache7.db"

sqlite3 "$database_file" "UPDATE Menu_roms SET disp = 'LEDS ($script_name)',pinyin = 'LEDS ($script_name)',cpinyin = 'LEDS ($script_name)',opinyin = 'LEDS ($script_name)' WHERE disp LIKE 'LEDS (%)';"
sqlite3 "$database_file" "UPDATE Menu_roms SET ppath = 'LEDS ($script_name)' WHERE ppath LIKE 'LEDS (%)';"
json_file="/tmp/state.json"

jq --arg script_name "$script_name" '.list |= map(if (.ppath | index("LEDS ")) then .ppath = "LEDS (\($script_name))" else . end)' "$json_file" >"$json_file.tmp" && mv "$json_file.tmp" "$json_file"

sync
sleep 0.1
pkill -f sdl2imgshow
