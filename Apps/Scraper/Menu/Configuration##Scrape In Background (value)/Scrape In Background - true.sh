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
/mnt/SDCARD/System/usr/trimui/scripts/mainui_state_update.sh "Scrape In Background" "$BackgroundState"