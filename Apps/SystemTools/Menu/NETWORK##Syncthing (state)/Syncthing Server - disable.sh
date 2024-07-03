#!/bin/sh

/mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "Applying \"$(basename "$0" .sh)\" by default..."

json_file="/mnt/SDCARD/System/etc/crossmix.json"

if [ ! -f "$json_file" ]; then
    echo "{}" >"$json_file"
fi

/mnt/SDCARD/System/bin/jq '. += {"Syncthing": 0}' "$json_file" >"/tmp/json_file.tmp" && mv "/tmp/json_file.tmp" "$json_file"
sync

pkill /mnt/SDCARD/System/bin/syncthing

PATH="/mnt/SDCARD/System/bin:$PATH"
export LD_LIBRARY_PATH="/mnt/SDCARD/System/lib:/usr/trimui/lib:$LD_LIBRARY_PATH"
database_file="/mnt/SDCARD/Apps/SystemTools/Menu/Menu_cache7.db"

sqlite3 "$database_file" "UPDATE Menu_roms SET disp = 'Syncthing (disabled)',pinyin = 'Syncthing (disabled)',cpinyin = 'Syncthing (disabled)',opinyin = 'Syncthing (disabled)' WHERE disp = 'Syncthing (enabled)';"
sqlite3 "$database_file" "UPDATE Menu_roms SET ppath = 'Syncthing (disabled)' WHERE ppath = 'Syncthing (enabled)';"
json_file="/tmp/state.json"

jq '.list |= map(if .ppath == "Syncthing (enabled)" then .ppath = "Syncthing (disabled)" else . end)' "$json_file" >"$json_file.tmp" && mv "$json_file.tmp" "$json_file"

sync

sleep 0.1
