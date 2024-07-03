#!/bin/sh

/mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "Applying \"$(basename "$0" .sh)\" by default..."

json_file="/mnt/SDCARD/System/etc/crossmix.json"

if [ ! -f "$json_file" ]; then
    echo "{}" >"$json_file"
fi

/mnt/SDCARD/System/bin/jq '. += {"SFTPGo": 0}' "$json_file" >"/tmp/json_file.tmp" && mv "/tmp/json_file.tmp" "$json_file"


sed -i 's/export NETWORK_SFTPGO="Y"/export NETWORK_SFTPGO="N"/' /mnt/SDCARD/System/etc/ex_config
pkill /mnt/SDCARD/System/sftpgo/sftpgo

PATH="/mnt/SDCARD/System/bin:$PATH"
export LD_LIBRARY_PATH="/mnt/SDCARD/System/lib:/usr/trimui/lib:$LD_LIBRARY_PATH"
database_file="/mnt/SDCARD/Apps/SystemTools/Menu/Menu_cache7.db"

sqlite3 "$database_file" "UPDATE Menu_roms SET disp = 'SFTPGo (disabled)',pinyin = 'SFTPGo (disabled)',cpinyin = 'SFTPGo (disabled)',opinyin = 'SFTPGo (disabled)' WHERE disp = 'SFTPGo (enabled)';"
sqlite3 "$database_file" "UPDATE Menu_roms SET ppath = 'SFTPGo (disabled)' WHERE ppath = 'SFTPGo (enabled)';"
json_file="/tmp/state.json"

jq '.list |= map(if .ppath == "SFTPGo (enabled)" then .ppath = "SFTPGo (disabled)" else . end)' "$json_file" >"$json_file.tmp" && mv "$json_file.tmp" "$json_file"

sync

sleep 0.1
