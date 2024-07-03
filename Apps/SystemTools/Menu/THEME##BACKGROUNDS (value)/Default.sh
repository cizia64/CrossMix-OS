#!/bin/sh
PATH="/mnt/SDCARD/System/bin:$PATH"
LD_LIBRARY_PATH="/mnt/SDCARD/System/lib:/usr/trimui/lib:$LD_LIBRARY_PATH"

/mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "Applying \"$(basename "$0" .sh)\" backgrounds by default..."

script_name=$(basename "$0" .sh)

find /mnt/SDCARD/Emus/ -name "config.json" -exec sh -c '
    bg_path="/mnt/SDCARD/Backgrounds/$1/$(basename "$(dirname "{}")").png"
    echo "bg_path $bg_path"
    /mnt/SDCARD/System/bin/jq --arg new_icon "$bg_path" ".background=\"$bg_path\"" "{}"  > /tmp/tmp_config.json && mv /tmp/tmp_config.json "{}"
' sh "$script_name" {} \;

json_file="/mnt/SDCARD/System/etc/crossmix.json"
if [ ! -f "$json_file" ]; then
    echo "{}" >"$json_file"
fi
/mnt/SDCARD/System/bin/jq --arg script_name "$script_name" '. += {"BACKGROUNDS": $script_name}' "$json_file" >"/tmp/json_file.tmp" && mv "/tmp/json_file.tmp" "$json_file"

database_file="/mnt/SDCARD/Apps/SystemTools/Menu/Menu_cache7.db"

sqlite3 "$database_file" "UPDATE Menu_roms SET disp = 'BACKGROUNDS ($script_name)',pinyin = 'BACKGROUNDS ($script_name)',cpinyin = 'BACKGROUNDS ($script_name)',opinyin = 'BACKGROUNDS ($script_name)' WHERE disp LIKE 'BACKGROUNDS (%)';"
sqlite3 "$database_file" "UPDATE Menu_roms SET ppath = 'BACKGROUNDS ($script_name)' WHERE ppath LIKE 'BACKGROUNDS (%)';"
json_file="/tmp/state.json"

jq --arg script_name "$script_name" '.list |= map(if (.ppath | index("BACKGROUNDS ")) then .ppath = "BACKGROUNDS (\($script_name))" else . end)' "$json_file" >"$json_file.tmp" && mv "$json_file.tmp" "$json_file"

sync
sleep 0.1
