#!/bin/sh
PATH="/mnt/SDCARD/System/bin:$PATH"
export LD_LIBRARY_PATH="/mnt/SDCARD/System/lib:/usr/trimui/lib:$LD_LIBRARY_PATH"

script_name=$(basename "$0" .sh)
lang_code=$(echo "$script_name" | cut -d ' ' -f 1 | cut -d '-' -f 1)

/mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "Applying \"$(basename "$0")\" by default..."

json_file="/mnt/SDCARD/System/etc/scraper.json"

if [ ! -f "$json_file" ]; then
  echo "{}" >"$json_file"
fi

/mnt/SDCARD/System/bin/jq --arg lang_code "$lang_code" '.Screenscraper_Region = $lang_code' "$json_file" >"/tmp/json_file.tmp" && mv "/tmp/json_file.tmp" "$json_file"

# we modify the DB entries to reflect the current state

database_file="/mnt/SDCARD/Apps/Scraper/Menu/Menu_cache7.db"

sqlite3 "$database_file" "UPDATE Menu_roms SET disp = 'Region ($script_name)',pinyin = 'Region ($script_name)',cpinyin = 'Region ($script_name)',opinyin = 'Region ($script_name)' WHERE disp LIKE 'Region (%)';"

sqlite3 "$database_file" "UPDATE Menu_roms SET ppath = 'Region ($script_name)' WHERE ppath LIKE 'Region (%)';"
json_file="/tmp/state.json"

jq --arg script_name "$script_name" '.list |= map(if (.ppath | index("Region ")) then .ppath = "Region (\($script_name))" else . end)' "$json_file" >"$json_file.tmp" && mv "$json_file.tmp" "$json_file"

sync
