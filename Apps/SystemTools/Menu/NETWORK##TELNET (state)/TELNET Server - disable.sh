#!/bin/sh
PATH="/mnt/SDCARD/System/bin:$PATH"
LD_LIBRARY_PATH="/mnt/SDCARD/System/lib:/usr/trimui/lib:$LD_LIBRARY_PATH"

/mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "Applying \"$(basename "$0" .sh)\" by default..."

json_file="/mnt/SDCARD/System/etc/crossmix.json"

if [ ! -f "$json_file" ]; then
    echo "{}" >"$json_file"
fi

/mnt/SDCARD/System/bin/jq '. += {"TELNET": 0}' "$json_file" >"/tmp/json_file.tmp" && mv "/tmp/json_file.tmp" "$json_file"

pkill telnetd


database_file="/mnt/SDCARD/Apps/SystemTools/Menu/Menu_cache7.db"

sqlite3 "$database_file" "UPDATE Menu_roms SET disp = 'TELNET (disabled)',pinyin = 'TELNET (disabled)',cpinyin = 'TELNET (disabled)',opinyin = 'TELNET (disabled)' WHERE disp = 'TELNET (enabled)';"
sqlite3 "$database_file" "UPDATE Menu_roms SET ppath = 'TELNET (disabled)' WHERE ppath = 'TELNET (enabled)';"
json_file="/tmp/state.json"

jq '.list |= map(if .ppath == "TELNET (enabled)" then .ppath = "TELNET (disabled)" else . end)' "$json_file" >"$json_file.tmp" && mv "$json_file.tmp" "$json_file"

sync

sleep 0.1
