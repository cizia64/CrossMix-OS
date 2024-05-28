#!/bin/sh
PATH="/mnt/SDCARD/System/bin:$PATH"
LD_LIBRARY_PATH="/mnt/SDCARD/System/lib:/usr/trimui/lib:$LD_LIBRARY_PATH"

/mnt/SDCARD/System/bin/sdl2imgshow \
    -i "/usr/trimui/res/skin/bg.png" \
    -f "/usr/trimui/res/regular.ttf" \
    -s 50 \
    -c "220,220,220" \
    -t "Applying \"$(basename "$0" .sh)\" by default..." &

cat >/tmp/ra_patch.cfg <<-EOM
savestate_auto_load = "false"
EOM

# Patch RA config
/mnt/SDCARD/System/usr/trimui/scripts/patch_ra_cfg.sh /tmp/ra_patch.cfg
rm /tmp/ra_patch.cfg

# Menu modification to reflect the change immediately

json_file="/mnt/SDCARD/System/etc/systemtools.json"
if [ ! -f "$json_file" ]; then
    echo "{}" >"$json_file"
fi

/mnt/SDCARD/System/bin/jq '. += {"AUTO LOAD STATE": 0}' "$json_file" >"/tmp/json_file.tmp" && mv "/tmp/json_file.tmp" "$json_file"

database_file="/mnt/SDCARD/Apps/SystemTools/Menu/Menu_cache7.db"

sqlite3 "$database_file" "UPDATE Menu_roms SET disp = 'AUTO LOAD STATE (disabled)',pinyin = 'AUTO LOAD STATE (disabled)',cpinyin = 'AUTO LOAD STATE (disabled)',opinyin = 'AUTO LOAD STATE (disabled)' WHERE disp = 'AUTO LOAD STATE (enabled)';"
sqlite3 "$database_file" "UPDATE Menu_roms SET ppath = 'AUTO LOAD STATE (disabled)' WHERE ppath = 'AUTO LOAD STATE (enabled)';"
json_file="/tmp/state.json"

jq '.list |= map(if .ppath == "AUTO LOAD STATE (enabled)" then .ppath = "AUTO LOAD STATE (disabled)" else . end)' "$json_file" >"$json_file.tmp" && mv "$json_file.tmp" "$json_file"

sync

sleep 0.1
pkill -f sdl2imgshow
