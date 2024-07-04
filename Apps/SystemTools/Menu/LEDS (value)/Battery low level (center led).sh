#!/bin/sh
PATH="/mnt/SDCARD/System/bin:$PATH"
LD_LIBRARY_PATH="/mnt/SDCARD/System/lib:/usr/trimui/lib:$LD_LIBRARY_PATH"

/mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "Applying \"$(basename "$0" .sh)\" mode..."

output_file="/mnt/SDCARD/System/etc/led_config.sh"
ScriptName=$(basename "$output_file")

LedLoop() {
    cat <<'EOF'
battery_capacity_file="/sys/devices/platform/soc/7081400.s_twi/i2c-6/6-0034/axp2202-bat-power-supply.0/power_supply/axp2202-battery/capacity"

while true; do
    battery_level=$(cat $battery_capacity_file)

    if [ "$battery_level" -lt 10 ]; then
        echo 1 >/sys/class/led_anim/effect_enable
        echo FF0000 >/sys/class/led_anim/effect_rgb_hex_m
        echo 60 >/sys/class/led_anim/effect_cycles_m
        echo 1000 >/sys/class/led_anim/effect_duration_m
        echo 3 >/sys/class/led_anim/effect_m
    else
        echo 1 >/sys/class/led_anim/effect_enable
        echo 000000 >/sys/class/led_anim/effect_rgb_hex_m
        echo 1000 >/sys/class/led_anim/effect_duration_m
        echo 3 >/sys/class/led_anim/effect_m
    fi

    sleep 60
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
