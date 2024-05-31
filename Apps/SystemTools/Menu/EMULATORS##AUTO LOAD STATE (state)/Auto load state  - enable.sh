#!/bin/sh
PATH="/mnt/SDCARD/System/bin:$PATH"
LD_LIBRARY_PATH="/mnt/SDCARD/System/lib:/usr/trimui/lib:$LD_LIBRARY_PATH"

/mnt/SDCARD/System/bin/sdl2imgshow \
    -i "/mnt/SDCARD/trimui/res/crossmix-os/bg-info.png" \
    -f "/mnt/SDCARD/System/resources/DejaVuSans.ttf" \
    -s 50 \
    -c "220,220,220" \
    -t "Applying \"$(basename "$0" .sh)\" by default..." &

cat >/tmp/crossmix_ra_patch.cfg <<-EOM
savestate_auto_load = "true"
EOM

# Patch RA config
/mnt/SDCARD/System/usr/trimui/scripts/patch_ra_cfg.sh /tmp/crossmix_ra_patch.cfg
rm /tmp/crossmix_ra_patch.cfg

json_file="/mnt/SDCARD/System/etc/crossmix.json"

if [ ! -f "$json_file" ]; then
    echo "{}" >"$json_file"
fi

# Use jq to insert or replace the "AUTO LOAD STATE" value with 1 in the JSON file.
/mnt/SDCARD/System/bin/jq '. += {"AUTO LOAD STATE": 1}' "$json_file" >"/tmp/json_file.tmp" && mv "/tmp/json_file.tmp" "$json_file"

# we modify the DB entries to reflect the current state

database_file="/mnt/SDCARD/Apps/SystemTools/Menu/Menu_cache7.db"

sqlite3 "$database_file" "UPDATE Menu_roms SET disp = 'AUTO LOAD STATE (enabled)',pinyin = 'AUTO LOAD STATE (enabled)',cpinyin = 'AUTO LOAD STATE (enabled)',opinyin = 'AUTO LOAD STATE (enabled)' WHERE disp = 'AUTO LOAD STATE (disabled)';"
sqlite3 "$database_file" "UPDATE Menu_roms SET ppath = 'AUTO LOAD STATE (enabled)' WHERE ppath = 'AUTO LOAD STATE (disabled)';"
sync
json_file="/tmp/state.json"

# we modify the current menu position as the DB entry has changed
jq '.list |= map(if .ppath == "AUTO LOAD STATE (disabled)" then .ppath = "AUTO LOAD STATE (enabled)" else . end)' "$json_file" >"$json_file.tmp" && mv "$json_file.tmp" "$json_file"

sleep 0.1
pkill -f sdl2imgshow
