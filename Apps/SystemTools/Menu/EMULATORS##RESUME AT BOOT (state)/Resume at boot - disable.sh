#!/bin/sh
PATH="/mnt/SDCARD/System/bin:$PATH"
LD_LIBRARY_PATH="/mnt/SDCARD/System/lib:/usr/trimui/lib:$LD_LIBRARY_PATH"

/mnt/SDCARD/System/bin/sdl2imgshow \
    -i "/usr/trimui/res/skin/bg.png" \
    -f "/mnt/SDCARD/System/resources/DejaVuSans.ttf" \
    -s 50 \
    -c "220,220,220" \
    -t "Applying \"$(basename "$0" .sh)\" by default..." &

json_file="/mnt/SDCARD/System/etc/crossmix.json"

if [ ! -f "$json_file" ]; then
    echo "{}" >"$json_file"
fi

# Use jq to insert or replace the "RESUME AT BOOT" value with 1 in the JSON file
/mnt/SDCARD/System/bin/jq '. += {"RESUME AT BOOT": 0}' "$json_file" >"/tmp/json_file.tmp" && mv "/tmp/json_file.tmp" "$json_file"

database_file="/mnt/SDCARD/Apps/SystemTools/Menu/Menu_cache7.db"

sqlite3 "$database_file" "UPDATE Menu_roms SET disp = 'RESUME AT BOOT (disabled)',pinyin = 'RESUME AT BOOT (disabled)',cpinyin = 'RESUME AT BOOT (disabled)',opinyin = 'RESUME AT BOOT (disabled)' WHERE disp = 'RESUME AT BOOT (enabled)';"
sqlite3 "$database_file" "UPDATE Menu_roms SET ppath = 'RESUME AT BOOT (disabled)' WHERE ppath = 'RESUME AT BOOT (enabled)';"
json_file="/tmp/state.json"

jq '.list |= map(if .ppath == "RESUME AT BOOT (enabled)" then .ppath = "RESUME AT BOOT (disabled)" else . end)' "$json_file" >"$json_file.tmp" && mv "$json_file.tmp" "$json_file"

sync

sleep 0.1
pkill -f sdl2imgshow
