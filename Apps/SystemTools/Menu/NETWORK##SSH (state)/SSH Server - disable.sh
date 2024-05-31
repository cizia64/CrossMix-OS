#!/bin/sh
PATH="/mnt/SDCARD/System/bin:$PATH"
LD_LIBRARY_PATH="/mnt/SDCARD/System/lib:/usr/trimui/lib:$LD_LIBRARY_PATH"

/mnt/SDCARD/System/bin/sdl2imgshow \
    -i "/mnt/SDCARD/trimui/res/crossmix-os/bg-info.png" \
    -f "/mnt/SDCARD/System/resources/DejaVuSans.ttf" \
    -s 50 \
    -c "220,220,220" \
    -t "Applying \"$(basename "$0" .sh)\" by default..." &

json_file="/mnt/SDCARD/System/etc/crossmix.json"

if [ ! -f "$json_file" ]; then
    echo "{}" >"$json_file"
fi

/mnt/SDCARD/System/bin/jq '. += {"SSH": 0}' "$json_file" >"/tmp/json_file.tmp" && mv "/tmp/json_file.tmp" "$json_file"

pkill dropbear
sed -i 's/export NETWORK_SSH="Y"/export NETWORK_SSH="N"/' /mnt/SDCARD/System/etc/ex_config

database_file="/mnt/SDCARD/Apps/SystemTools/Menu/Menu_cache7.db"

sqlite3 "$database_file" "UPDATE Menu_roms SET disp = 'SSH (disabled)',pinyin = 'SSH (disabled)',cpinyin = 'SSH (disabled)',opinyin = 'SSH (disabled)' WHERE disp = 'SSH (enabled)';"
sqlite3 "$database_file" "UPDATE Menu_roms SET ppath = 'SSH (disabled)' WHERE ppath = 'SSH (enabled)';"
json_file="/tmp/state.json"

jq '.list |= map(if .ppath == "SSH (enabled)" then .ppath = "SSH (disabled)" else . end)' "$json_file" >"$json_file.tmp" && mv "$json_file.tmp" "$json_file"

sync

sleep 0.1
pkill -f sdl2imgshow
