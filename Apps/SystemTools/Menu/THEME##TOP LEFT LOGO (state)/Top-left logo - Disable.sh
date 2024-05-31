#!/bin/sh
PATH="/mnt/SDCARD/System/bin:$PATH"
LD_LIBRARY_PATH="/mnt/SDCARD/System/lib:/usr/trimui/lib:$LD_LIBRARY_PATH"

/mnt/SDCARD/System/bin/sdl2imgshow \
    -i "/mnt/SDCARD/trimui/res/crossmix-os/bg-info.png" \
    -f "/mnt/SDCARD/System/resources/DejaVuSans.ttf" \
    -s 50 \
    -c "220,220,220" \
    -t "Applying \"$(basename "$0" .sh)\" by default..." &

CurrentTheme=$(/mnt/SDCARD/System/bin/jq -r .theme /mnt/UDISK/system.json)
cd "$CurrentTheme/skin/"

if [ ! -f ./nav-logo-off.png ]; then
    mv ./nav-logo.png ./nav-logo-off.png
    cp /mnt/SDCARD/System/usr/trimui/res/skin/empty.png ./nav-logo.png
else
    echo "The file ./nav-logo-off.png already exists."
fi

if [ ! -f ./icon-back-off.png ]; then
    mv ./icon-back.png ./icon-back-off.png
    cp /mnt/SDCARD/System/usr/trimui/res/skin/empty.png ./icon-back.png
else
    echo "The file ./nav-logo-off.png already exists."
fi

sync

# Menu modification to reflect the change immediately

json_file="/mnt/SDCARD/System/etc/crossmix.json"
if [ ! -f "$json_file" ]; then
    echo "{}" >"$json_file"
fi

database_file="/mnt/SDCARD/Apps/SystemTools/Menu/Menu_cache7.db"

sqlite3 "$database_file" "UPDATE Menu_roms SET disp = 'TOP LEFT LOGO (disabled)',pinyin = 'TOP LEFT LOGO (disabled)',cpinyin = 'TOP LEFT LOGO (disabled)',opinyin = 'TOP LEFT LOGO (disabled)' WHERE disp = 'TOP LEFT LOGO (enabled)';"
sqlite3 "$database_file" "UPDATE Menu_roms SET ppath = 'TOP LEFT LOGO (disabled)' WHERE ppath = 'TOP LEFT LOGO (enabled)';"
json_file="/tmp/state.json"

jq '.list |= map(if .ppath == "TOP LEFT LOGO (enabled)" then .ppath = "TOP LEFT LOGO (disabled)" else . end)' "$json_file" >"$json_file.tmp" && mv "$json_file.tmp" "$json_file"

sync

sleep 0.1
pkill -f sdl2imgshow
