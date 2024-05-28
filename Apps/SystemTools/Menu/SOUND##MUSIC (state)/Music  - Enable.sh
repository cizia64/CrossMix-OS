#!/bin/sh
PATH="/mnt/SDCARD/System/bin:$PATH"
LD_LIBRARY_PATH="/mnt/SDCARD/System/lib:/usr/trimui/lib:$LD_LIBRARY_PATH"

/mnt/SDCARD/System/bin/sdl2imgshow \
    -i "/usr/trimui/res/skin/bg.png" \
    -f "/mnt/SDCARD/System/resources/DejaVuSans.ttf" \
    -s 40 \
    -c "220,220,220" \
    -t "Applying \"$(basename "$0" .sh)\" on current theme." &

CurrentTheme=$(/mnt/SDCARD/System/bin/jq -r .theme /mnt/UDISK/system.json)
cd "$CurrentTheme/sound/"
mv ./bgm-off.mp3 ./bgm.mp3

# we modify the DB entries to reflect the current state

database_file="/mnt/SDCARD/Apps/SystemTools/Menu/Menu_cache7.db"

sqlite3 "$database_file" "UPDATE Menu_roms SET disp = 'MUSIC (enabled)',pinyin = 'MUSIC (enabled)',cpinyin = 'MUSIC (enabled)',opinyin = 'MUSIC (enabled)' WHERE disp = 'MUSIC (disabled)';"
sqlite3 "$database_file" "UPDATE Menu_roms SET ppath = 'MUSIC (enabled)' WHERE ppath = 'MUSIC (disabled)';"
sync
json_file="/tmp/state.json"

# we modify the current menu position as the DB entry has changed
jq '.list |= map(if .ppath == "MUSIC (disabled)" then .ppath = "MUSIC (enabled)" else . end)' "$json_file" >"$json_file.tmp" && mv "$json_file.tmp" "$json_file"

sleep 0.1
pkill -f sdl2imgshow
