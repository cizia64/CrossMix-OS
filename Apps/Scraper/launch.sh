#!/bin/sh

echo performance >/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
echo 1416000 >/sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq

PATH="/mnt/SDCARD/System/bin:$PATH"
export LD_LIBRARY_PATH="/mnt/SDCARD/System/lib:/usr/trimui/lib:$LD_LIBRARY_PATH"

/mnt/SDCARD/System/bin/sdl2imgshow \
    -i "/mnt/SDCARD/trimui/res/crossmix-os/bg-info.png" \
    -f "/mnt/SDCARD/System/resources/DejaVuSans.ttf" \
    -s 30 \
    -c "220,220,220" \
    -t "Loading..." &
sleep 0.3
pkill -f sdl2imgshow



# For faster loading we check if we have to rebuild the database

show_json_path="/mnt/SDCARD/Emus/show.json"
database_file="/mnt/SDCARD/Apps/Scraper/Menu/Menu_cache7.db"

crc_Emus_file="/mnt/SDCARD/Apps/Scraper/show_json_crc.txt"
crc_DB_file="/mnt/SDCARD/Apps/Scraper/current_crc_DB.txt"

# Calculate current CRC32 of show.json (list of displayed emulators) and Menu_cache7.db
current_crc_Emus=$(crc32 "$show_json_path" | awk '{print $1}')
current_crc_DB=$(crc32 "$database_file" | awk '{print $1}')

# get previous values
previous_crc_Emus=$(cat "$crc_Emus_file")
previous_crc_DB=$(cat "$crc_DB_file")


echo "Current  show.json CRC32: $current_crc_Emus      |    Current   Menu_cache7.db CRC32: $current_crc_DB"
echo "Previous show.json CRC32: $previous_crc_Emus      |    Previous  Menu_cache7.db CRC32: $previous_crc_DB"




# If CRC32 have changed, perform operations and update CRC file
if [ "$current_crc_Emus" != "$previous_crc_Emus" ] || [ "$current_crc_DB" != "$previous_crc_DB" ]; then
    
    echo "CRC32 changed. Performing operations..."
    echo "$current_crc_Emus" >"$crc_Emus_file"
    rm -f "$database_file"
    sqlite3 "$database_file" "CREATE TABLE Menu_roms (id INTEGER PRIMARY KEY, disp TEXT, path TEXT, imgpath TEXT, type INTEGER, ppath TEXT, pinyin TEXT, cpinyin TEXT, opinyin TEXT);"
    sync

    labels=$(jq -r '.[] | select(.show == 1) | .label' "$show_json_path" | tr '\n' '|')
    labels_string=$(echo "$labels")

    # Function to check if an element is in the labels string
    contains() {
        case "$labels_string" in
        *"$1"*) return 0 ;;
        *) return 1 ;;
        esac
    }

    echo "Labels: $labels_string"

    for dir in /mnt/SDCARD/Emus/*/; do
        config_json_path="${dir}config.json"

        if [ -f "$config_json_path" ]; then
            config_label=$(jq -r '.label' "$config_json_path")

            if contains "$config_label"; then
                rompath=$(jq -r '.rompath' "$config_json_path")
                rom_folder=$(basename "$rompath")
                imgpath="/mnt/SDCARD/Icons/Default/Logos/$(basename "$rom_folder").png"

                # Add present rom folders
                subfolder_query="INSERT INTO Menu_roms (disp, path, imgpath, type, ppath, pinyin, cpinyin, opinyin) VALUES (\"$config_label\", \"$rom_folder\", \"$imgpath\", 1, \".\", \"$config_label\", \"$config_label\", \"$config_label\")"
                sqlite3 "$database_file" "$subfolder_query"

                # Add default options for each folder: "Scrape all"
                query="INSERT INTO Menu_roms (disp, path, imgpath, type, ppath, pinyin, cpinyin, opinyin) VALUES (\"Scrape all $rom_folder games.\", \"$rom_folder\", \"$imgpath\", 0, \"$config_label\", \"Scrape all\", \"Scrape all\", \"Scrape all\")"
                sqlite3 "$database_file" "$query"

                sync
                echo "Label: $config_label, ROM Folder: $rom_folder, Image Path: $imgpath"
            fi
        fi
    done
    crc32 "$database_file"  | awk '{print $1}' >"$crc_DB_file"
    sync

else
    echo "CRC32 has not changed. No operations performed."
fi

cp /mnt/SDCARD/Apps/Scraper/GoTo_Scraper_List.json /tmp/state.json
sync
