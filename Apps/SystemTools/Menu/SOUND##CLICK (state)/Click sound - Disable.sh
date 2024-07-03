#!/bin/sh
PATH="/mnt/SDCARD/System/bin:$PATH"
LD_LIBRARY_PATH="/mnt/SDCARD/System/lib:/usr/trimui/lib:$LD_LIBRARY_PATH"

/mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "Applying \"$(basename "$0" .sh)\" on current theme."

CurrentTheme=$(/mnt/SDCARD/System/bin/jq -r .theme /mnt/UDISK/system.json)
cd "$CurrentTheme/sound/"
mv ./click.wav ./click-off.wav

# Menu modification to reflect the change immediately

json_file="/mnt/SDCARD/System/etc/crossmix.json"
if [ ! -f "$json_file" ]; then
    echo "{}" >"$json_file"
fi

database_file="/mnt/SDCARD/Apps/SystemTools/Menu/Menu_cache7.db"

sqlite3 "$database_file" "UPDATE Menu_roms SET disp = 'CLICK (disabled)',pinyin = 'CLICK (disabled)',cpinyin = 'CLICK (disabled)',opinyin = 'CLICK (disabled)' WHERE disp = 'CLICK (enabled)';"
sqlite3 "$database_file" "UPDATE Menu_roms SET ppath = 'CLICK (disabled)' WHERE ppath = 'CLICK (enabled)';"
json_file="/tmp/state.json"

jq '.list |= map(if .ppath == "CLICK (enabled)" then .ppath = "CLICK (disabled)" else . end)' "$json_file" >"$json_file.tmp" && mv "$json_file.tmp" "$json_file"

sync

sleep 0.1
