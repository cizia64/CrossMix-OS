#!/bin/sh
PATH="/mnt/SDCARD/System/bin:$PATH"
LD_LIBRARY_PATH="/mnt/SDCARD/System/lib:/usr/trimui/lib:$LD_LIBRARY_PATH"

/mnt/SDCARD/System/bin/sdl2imgshow \
    -i "/usr/trimui/res/skin/bg.png" \
    -f "/usr/trimui/res/regular.ttf" \
    -s 50 \
    -c "220,220,220" \
    -t "Applying \"$(basename "$0" .sh)\" by default..." &

CurrentTheme=$(/mnt/SDCARD/System/bin/jq -r .theme /mnt/UDISK/system.json)
cd "$CurrentTheme/skin/"

if [ -f ./nav-logo-off.png ]; then
    mv ./nav-logo-off.png ./nav-logo.png
else
    echo "The file ./nav-logo-off.png doesn't exists."
fi

if [ -f ./icon-back-off.png ]; then
    mv ./icon-back-off.png ./icon-back.png
else
    echo "The file ./icon-back-off.png doesn't exists."
fi

sync

# we modify the DB entries to reflect the current state

database_file="/mnt/SDCARD/Apps/SystemTools/Menu/Menu_cache7.db"

sqlite3 "$database_file" "UPDATE Menu_roms SET disp = 'TOP LEFT LOGO (enabled)',pinyin = 'TOP LEFT LOGO (enabled)',cpinyin = 'TOP LEFT LOGO (enabled)',opinyin = 'TOP LEFT LOGO (enabled)' WHERE disp = 'TOP LEFT LOGO (disabled)';"
sqlite3 "$database_file" "UPDATE Menu_roms SET ppath = 'TOP LEFT LOGO (enabled)' WHERE ppath = 'TOP LEFT LOGO (disabled)';"
sync
json_file="/tmp/state.json"

# we modify the current menu position as the DB entry has changed
jq '.list |= map(if .ppath == "TOP LEFT LOGO (disabled)" then .ppath = "TOP LEFT LOGO (enabled)" else . end)' "$json_file" >"$json_file.tmp" && mv "$json_file.tmp" "$json_file"

sleep 0.1
pkill -f sdl2imgshow
