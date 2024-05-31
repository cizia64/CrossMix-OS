#!/bin/sh
PATH="/mnt/SDCARD/System/bin:$PATH"
LD_LIBRARY_PATH="/mnt/SDCARD/System/lib:/usr/trimui/lib:$LD_LIBRARY_PATH"

/mnt/SDCARD/System/bin/sdl2imgshow \
    -i "/mnt/SDCARD/trimui/res/crossmix-os/bg-info.png" \
    -f "/mnt/SDCARD/System/resources/DejaVuSans.ttf" \
    -s 30 \
    -c "220,220,220" \
    -t "Applying \"$(basename "$0" .sh)\" icons by default..." &

script_name=$(basename "$0" .sh)

find /mnt/SDCARD/Emus/ -name "config.json" -exec sh -c '
    icons_path="/mnt/SDCARD/Icons/$1/Emus/$(basename "$(dirname "{}")").png"
    echo "icons_path $icons_path"
    /mnt/SDCARD/System/bin/jq --arg new_icon "$icons_path" ".icon=\"$icons_path\"" "{}"  > /tmp/tmp_config.json && mv /tmp/tmp_config.json "{}"
' sh "$script_name" {} \;

json_file="/mnt/SDCARD/System/etc/crossmix.json"
if [ ! -f "$json_file" ]; then
    echo "{}" >"$json_file"
fi
/mnt/SDCARD/System/bin/jq --arg script_name "$script_name" '. += {"ICONS": $script_name}' "$json_file" >"/tmp/json_file.tmp" && mv "/tmp/json_file.tmp" "$json_file"

database_file="/mnt/SDCARD/Apps/SystemTools/Menu/Menu_cache7.db"

sqlite3 "$database_file" "UPDATE Menu_roms SET disp = 'ICONS ($script_name)',pinyin = 'ICONS ($script_name)',cpinyin = 'ICONS ($script_name)',opinyin = 'ICONS ($script_name)' WHERE disp LIKE 'ICONS (%)';"
sqlite3 "$database_file" "UPDATE Menu_roms SET ppath = 'ICONS ($script_name)' WHERE ppath LIKE 'ICONS (%)';"
json_file="/tmp/state.json"

jq --arg script_name "$script_name" '.list |= map(if (.ppath | index("ICONS ")) then .ppath = "ICONS (\($script_name))" else . end)' "$json_file" >"$json_file.tmp" && mv "$json_file.tmp" "$json_file"

sync
sleep 0.1
pkill -f sdl2imgshow
