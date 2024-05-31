#!/bin/sh
PATH="/mnt/SDCARD/System/bin:$PATH"
LD_LIBRARY_PATH="/mnt/SDCARD/System/lib:/usr/trimui/lib:$LD_LIBRARY_PATH"

/mnt/SDCARD/System/bin/sdl2imgshow \
    -i "/mnt/SDCARD/trimui/res/crossmix-os/bg-info.png" \
    -f "/mnt/SDCARD/System/resources/DejaVuSans.ttf" \
    -s 40 \
    -c "220,220,220" \
    -t "Applying \"$(basename "$0" .sh)\" on current theme." &

CurrentTheme=$(/mnt/SDCARD/System/bin/jq -r .theme /mnt/UDISK/system.json)
cd "$CurrentTheme/sound/"
mv ./bgm.mp3 ./bgm-off.mp3

# Menu modification to reflect the change immediately

json_file="/mnt/SDCARD/System/etc/crossmix.json"
if [ ! -f "$json_file" ]; then
    echo "{}" >"$json_file"
fi

database_file="/mnt/SDCARD/Apps/SystemTools/Menu/Menu_cache7.db"

sqlite3 "$database_file" "UPDATE Menu_roms SET disp = 'MUSIC (disabled)',pinyin = 'MUSIC (disabled)',cpinyin = 'MUSIC (disabled)',opinyin = 'MUSIC (disabled)' WHERE disp = 'MUSIC (enabled)';"
sqlite3 "$database_file" "UPDATE Menu_roms SET ppath = 'MUSIC (disabled)' WHERE ppath = 'MUSIC (enabled)';"
json_file="/tmp/state.json"

jq '.list |= map(if .ppath == "MUSIC (enabled)" then .ppath = "MUSIC (disabled)" else . end)' "$json_file" >"$json_file.tmp" && mv "$json_file.tmp" "$json_file"

sync

sleep 0.1
pkill -f sdl2imgshow
