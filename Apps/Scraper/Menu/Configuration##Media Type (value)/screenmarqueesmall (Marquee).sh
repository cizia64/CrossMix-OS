#!/bin/sh
PATH="/mnt/SDCARD/System/bin:$PATH"
export LD_LIBRARY_PATH="/mnt/SDCARD/System/lib:/usr/trimui/lib:$LD_LIBRARY_PATH"

script_name=$(basename "$0" .sh)
media_type=$(echo "$script_name" | awk '{print $1}')

/mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "Applying \"$(basename "$0")\" by default..."

json_file="/mnt/SDCARD/System/etc/scraper.json"

if [ ! -f "$json_file" ]; then
  echo "{}" >"$json_file"
fi

/mnt/SDCARD/System/bin/jq --arg media_type "$media_type" '.Screenscraper_MediaType = $media_type' "$json_file" >"/tmp/json_file.tmp" && mv "/tmp/json_file.tmp" "$json_file"

# we modify the DB entries to reflect the current state

database_file="/mnt/SDCARD/Apps/Scraper/Menu/Menu_cache7.db"

sqlite3 "$database_file" "UPDATE Menu_roms SET disp = 'Media Type ($media_type)',pinyin = 'Media Type ($media_type)',cpinyin = 'Media Type ($media_type)',opinyin = 'Media Type ($media_type)' WHERE disp LIKE 'Media Type (%)';"

sqlite3 "$database_file" "UPDATE Menu_roms SET ppath = 'Media Type ($media_type)' WHERE ppath LIKE 'Media Type (%)';"
json_file="/tmp/state.json"

jq --arg media_type "$media_type" '.list |= map(if (.ppath | index("Media Type ")) then .ppath = "Media Type (\($media_type))" else . end)' "$json_file" >"$json_file.tmp" && mv "$json_file.tmp" "$json_file"

sync
