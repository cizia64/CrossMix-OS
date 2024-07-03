#!/bin/sh
PATH="/mnt/SDCARD/System/bin:$PATH"
export LD_LIBRARY_PATH="/mnt/SDCARD/System/lib:/usr/trimui/lib:$LD_LIBRARY_PATH"

script_name=$(basename "$0" .sh)
BackgroundState=$(echo "$script_name" | cut -d '-' -f 2 | tr -d ' ')

/mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "Applying \"$(basename "$0")\" by default..."

json_file="/mnt/SDCARD/System/etc/scraper.json"

if [ ! -f "$json_file" ]; then
  echo "{}" >"$json_file"
fi

/mnt/SDCARD/System/bin/jq --arg BackgroundState "$BackgroundState" '.ScrapeInBackground = $BackgroundState' "$json_file" >"/tmp/json_file.tmp" && mv "/tmp/json_file.tmp" "$json_file"

# we modify the DB entries to reflect the current state

database_file="/mnt/SDCARD/Apps/Scraper/Menu/Menu_cache7.db"

sqlite3 "$database_file" "UPDATE Menu_roms SET disp = 'Scrape In Background ($BackgroundState)',pinyin = 'Scrape In Background ($BackgroundState)',cpinyin = 'Scrape In Background ($BackgroundState)',opinyin = 'Scrape In Background ($BackgroundState)' WHERE disp LIKE 'Scrape In Background (%)';"

sqlite3 "$database_file" "UPDATE Menu_roms SET ppath = 'Scrape In Background ($BackgroundState)' WHERE ppath LIKE 'Scrape In Background (%)';"
json_file="/tmp/state.json"

jq --arg BackgroundState "$BackgroundState" '.list |= map(if (.ppath | index("Scrape In Background ")) then .ppath = "Scrape In Background (\($BackgroundState))" else . end)' "$json_file" >"$json_file.tmp" && mv "$json_file.tmp" "$json_file"

sync
