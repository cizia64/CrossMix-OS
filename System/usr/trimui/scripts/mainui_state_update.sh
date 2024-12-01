#!/bin/sh

# Function used by "System Tools" app to update the MainUI folder which is currently browsed.
# it allows to modify the MainUI current folder name during a script and go back in this new folder name
# (otherwise you'll be in a MainUI folder which doesn't exist anymore which is broking the current database)
# For example you're in System Tools -> "LEDS (Default)" section, you select LEDS -> "Battery Level",
# The current section will be renamed: mainui_state_update.sh "LEDS" "Battery Level"

# Export necessary environment variables
export PATH="/mnt/SDCARD/System/bin:$PATH"
export LD_LIBRARY_PATH="/mnt/SDCARD/System/lib:/usr/trimui/lib:$LD_LIBRARY_PATH"

mainui_state_update() {
    local label_str="$1"
    local value_str="$2"

    # Check if parameters are initialized
    if [ -z "$label_str" ] || [ -z "$value_str" ]; then
        echo "Usage: $0 <label_str> <value_str>"
        exit 1
    fi

    # Update the SQLite database
    if grep -q "_SystemTools" /tmp/state.json; then
        database_file="/mnt/SDCARD/Apps/SystemTools/Menu/Menu_cache7.db"
    else
        database_file="/mnt/SDCARD/Apps/Scraper/Menu/Menu_cache7.db"
    fi

    sqlite3 "$database_file" <<EOF
UPDATE Menu_roms SET disp = '$label_str ($value_str)', pinyin = '$label_str ($value_str)', cpinyin = '$label_str ($value_str)', opinyin = '$label_str ($value_str)' WHERE disp LIKE '$label_str (%)';
UPDATE Menu_roms SET ppath = '$label_str ($value_str)' WHERE ppath LIKE '$label_str (%)';
EOF

    # Update the state.json file if it exists
    json_file="/tmp/state.json"
    if [ -f "$json_file" ]; then
        /mnt/SDCARD/System/bin/jq --arg value_str "$value_str" --arg label_str "$label_str" \
            '.list |= map(if (.ppath | index($label_str)) then .ppath = "\($label_str) (\($value_str))" else . end)' \
            "$json_file" >"$json_file.tmp" && mv "$json_file.tmp" "$json_file"
    fi
    sync
    sleep 0.1
}

mainui_state_update "$1" "$2"
