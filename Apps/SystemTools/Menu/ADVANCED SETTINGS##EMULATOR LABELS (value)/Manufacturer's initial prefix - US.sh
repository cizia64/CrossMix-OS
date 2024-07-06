#!/bin/sh

# Export necessary environment variables
export PATH="/mnt/SDCARD/System/bin:$PATH"
export LD_LIBRARY_PATH="/mnt/SDCARD/System/lib:/usr/trimui/lib:$LD_LIBRARY_PATH"

# Display a message indicating the application of default icons
/mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "Applying \"$(basename "$0" .sh)\" icons by default..."

# Get the script name without the extension
script_name=$(basename "$0" .sh)

# Path to the SQLite database
db_path="/mnt/SDCARD/System/usr/trimui/scripts/emulators_list.db"

# Iterate over all directories in /mnt/SDCARD/Emus/
for dir in /mnt/SDCARD/Emus/*/; do
  folder_name=$(basename "$dir")
  # Skip directories starting with an underscore
  if [[ "$folder_name" == _* ]]; then
    echo "Skipping $folder_name"
    continue
  fi
  
  config_file="${dir}config.json"
  if [ -f "$config_file" ]; then
    # Retrieve the manufacturer and trimui_name_short_US from the database
    manufacturer=$(sqlite3 "$db_path" "SELECT manufacturer FROM systems WHERE crossmix_foldername = '$folder_name'")
    trimui_name_short_US=$(sqlite3 "$db_path" "SELECT trimui_name_short_US FROM systems WHERE crossmix_foldername = '$folder_name'")
    if [ -n "$manufacturer" ] && [ -n "$trimui_name_short_US" ]; then
      # Construct the crossmix_name
      first_three_letters=$(echo "$manufacturer" | cut -c1-3)
      crossmix_name="$first_three_letters. $trimui_name_short_US"
      # Update the label value in the JSON file
      /mnt/SDCARD/System/bin/jq --arg new_label "$crossmix_name" '.label = $new_label' "$config_file" > /tmp/tmp_config.json && mv /tmp/tmp_config.json "$config_file"
      echo "Updated label in $folder_name to \"$crossmix_name\""
    else
      echo "No manufacturer or trimui_name_short_US found for folder $folder_name"
    fi
  fi
done

# Check for the existence of crossmix.json and update it
json_file="/mnt/SDCARD/System/etc/crossmix.json"
if [ ! -f "$json_file" ]; then
  echo "{}" >"$json_file"
fi
/mnt/SDCARD/System/bin/jq --arg script_name "$script_name" '. += {"EMU LABELS": $script_name}' "$json_file" >"/tmp/json_file.tmp" && mv "/tmp/json_file.tmp" "$json_file"

# Update the SQLite database
database_file="/mnt/SDCARD/Apps/SystemTools/Menu/Menu_cache7.db"
sqlite3 "$database_file" <<EOF
UPDATE Menu_roms SET disp = 'EMULATOR LABELS ($script_name)', pinyin = 'EMULATOR LABELS ($script_name)', cpinyin = 'EMULATOR LABELS ($script_name)', opinyin = 'EMULATOR LABELS ($script_name)' WHERE disp LIKE 'EMULATOR LABELS (%)';
UPDATE Menu_roms SET ppath = 'EMULATOR LABELS ($script_name)' WHERE ppath LIKE 'EMULATOR LABELS (%)';
EOF

# Update the state.json file if it exists
json_file="/tmp/state.json"
if [ -f "$json_file" ]; then
  /mnt/SDCARD/System/bin/jq --arg script_name "$script_name" '.list |= map(if (.ppath | index("EMULATOR LABELS ")) then .ppath = "EMULATOR LABELS (\($script_name))" else . end)' "$json_file" > "$json_file.tmp" && mv "$json_file.tmp" "$json_file"
fi

# Synchronize the filesystem
sync
sleep 0.1

# Labels has changed so the Emulator selection must be done again:
/mnt/SDCARD/Apps/EmuCleaner/launch.sh -s
