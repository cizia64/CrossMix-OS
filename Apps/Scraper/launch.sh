#!/bin/sh

echo performance >/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
echo 1416000 >/sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq

PATH="/mnt/SDCARD/System/bin:$PATH"
export LD_LIBRARY_PATH="/mnt/SDCARD/System/lib:/usr/trimui/lib:$LD_LIBRARY_PATH"

/mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "Loading..."

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
echo "Previous show.json CRC32: $previous_crc_Emus     |    Previous  Menu_cache7.db CRC32: $previous_crc_DB"

sync
contains_hashes=$(sqlite3 "$database_file" "SELECT COUNT(*) FROM Menu_roms WHERE disp LIKE '%##%';")
# If any 'disp' field contains '##', delete the database
if [ "$contains_hashes" -gt 0 ]; then
	rm -f "$database_file"
	echo "Corrupted Ssraper database, re-building..."
fi

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
        subdir=$(basename "$dir")
		if [[ "$subdir" == _* ]]; then
			continue
		fi
		case "$subdir" in
			MUSIC|VIDEOS|CANNONBALL|CAVESTORY|CHAILOVE|DINOTHAWR|DOOM|ENTERPRISE|FLASHBACK|PGM|TI83|TYRQUAKE|VIDEOTON|VMAC|XRICK)
			continue
			;;
		esac

        if [ -f "$config_json_path" ]; then
            config_label=$(jq -r '.label' "$config_json_path")

            if contains "$config_label"; then
                rompath=$(jq -r '.rompath' "$config_json_path")
                rom_folder=$(basename "$rompath")
                imgpath="/mnt/SDCARD/Icons/Default/Logos/$(basename "$rom_folder").png"

                # Add present rom folders
				
				# sub folders disabled while we have only one option per emulator:
                # subfolder_query="INSERT INTO Menu_roms (disp, path, imgpath, type, ppath, pinyin, cpinyin, opinyin) VALUES (\"$config_label\", \"$rom_folder\", \"$imgpath\", 1, \".\", \"$config_label\", \"$config_label\", \"$config_label\")"
                # sqlite3 "$database_file" "$subfolder_query"

                # Add default options for each folder: "Scrape all"
                # query="INSERT INTO Menu_roms (disp, path, imgpath, type, ppath, pinyin, cpinyin, opinyin) VALUES (\"Scrape all $rom_folder games.\", \"$rom_folder\", \"$imgpath\", 0, \"$config_label\", \"Scrape all\", \"Scrape all\", \"Scrape all\")"
                # sqlite3 "$database_file" "$query"
				
                query="INSERT INTO Menu_roms (disp, path, imgpath, type, ppath, pinyin, cpinyin, opinyin) VALUES (\"$rom_folder - scraping.\", \"$rom_folder\", \"$imgpath\", 0, \".\", \"Scrape all $rom_folder games.\", \"Scrape all $rom_folder games.\", \"Scrape all $rom_folder games.\")"
                sqlite3 "$database_file" "$query"

                sync
                echo "Label: $config_label, ROM Folder: $rom_folder, Image Path: $imgpath"
            fi
        fi
    done
	
	
search_path="/mnt/SDCARD/Apps/Scraper/Menu/"
img_path="/mnt/SDCARD/Apps/Scraper/Menu/Imgs"

# ================================================= Create folders items in database =================================================
# Scan files in the rompath directory


for folder in "$search_path"/*/; do
  # Extract the folder name
  folder_name=$(basename "$folder")

  # Check if the folder is the "Imgs" directory
  if [ "$folder_name" = "Imgs" ]; then
    # Skip the "Imgs" directory
    continue
  fi

  if [ "${subfolder%/}" = "${search_path%/}" ]; then
    ppath="."
  else
    ppath="${subfolder##*/}"
    folder_escaped=$(echo "$folder_name" | sed "s/'/''/g")
  fi

  # Create an entry for the folder as if it were a game
  subfolder_query="INSERT INTO Menu_roms (disp, path, imgpath, type, ppath, pinyin, cpinyin, opinyin) VALUES (\"$folder_escaped\", \"$folder\", \"${img_path}/${folder_name}.png\", 1, \".\", \"$folder_escaped\", \"$folder_escaped\", \"$folder_escaped\")"
  sqlite3 "$database_file" "$subfolder_query"
  sync
done


	
# ================================================= Create script items in database =================================================


find "$search_path" -mindepth 1 -maxdepth 2 -type f -name "*.sh" | while read -r file; do
  # Skip files starting with a dot (.)
  filename=$(basename "$file")
  if [ "${filename#.*}" != "$filename" ]; then
    continue
  fi

  filename_without_ext="${filename%.*}"

  # Escape single quotes in the filename
  escaped_filename=$(echo "$filename_without_ext" | sed "s/'/''/g")

  if [ "$escaped_filename" = "Default" ]; then
    escaped_filename=" $escaped_filename"
  fi

  # Determine the subfolder (ppath)
  subfolder=$(dirname "$file")
  if [ "${subfolder%/}" = "${search_path%/}" ]; then
    ppath="."
  else
    ppath="${subfolder##*/}"
  fi

  # Set the imgpath with the subfolder "Imgs"
  imgpath="$img_path/$(basename "$subfolder")/${filename%.*}.png"

  # Prepare the SQLite query with double quotes around the filename, ppath, and imgpath
  query="INSERT INTO Menu_roms (disp, path, imgpath, type, ppath, pinyin, cpinyin, opinyin) VALUES (\"$escaped_filename\", \"$file\", \"$imgpath\", 0, \"$ppath\", \"$escaped_filename\", \"$escaped_filename\", \"$escaped_filename\")"
  sqlite3 "$database_file" "$query"
  sync

  echo "Entry created for file: $file"

done

sync
# ================================================= Create subfolders hierarchy in database =================================================


# select all folder containing "##"
sqlite3 "$database_file" "SELECT path FROM Menu_roms WHERE path LIKE '%##%' AND type = 1;" |
  while IFS= read -r path; do
    subdir_name=$(basename "$path")
    parentFolder="${subdir_name%%##*}"
    subFolder="${subdir_name#*##}"
    echo "---"
    echo "Folder full path: $path"
    echo "parentFolder: $parentFolder"
    echo "subFolder: $subFolder"

    # Create folder hierarchy
    sqlite3 "$database_file" "UPDATE Menu_roms SET disp = '$subFolder',pinyin = '$subFolder',cpinyin = '$subFolder',opinyin = '$subFolder' , ppath = '$parentFolder' WHERE path = '$path';"

    # Change each script item with new virtual subfolder
    sqlite3 "$database_file" "UPDATE Menu_roms SET ppath = '$subFolder' WHERE ppath = '$subdir_name';"
  done
sync
	
# ================================================= we modify the DB entries to reflect the current state =================================================


sqlite3 "$database_file" "SELECT disp, path FROM Menu_roms WHERE type = 1 AND disp LIKE '% (value)' ;" |
  while IFS='|' read -r disp path; do
    disp_withoutvalue=$(echo "$disp" | sed 's/ (value)//g')
	json_keyname=$(echo "$disp_withoutvalue" | tr -d ' ') # remove spaces
	if ! [ "$json_keyname" = "ScrapeInBackground" ]; then
		json_keyname="Screenscraper_$json_keyname"
	fi
    CurState=$(jq -r --arg disp "$json_keyname" '.[$disp] // "Default"' "/mnt/SDCARD/System/etc/scraper.json")
    if [ -z "$CurState" ]; then
      CurState="not set"
    fi
    disp_withvalue="$disp_withoutvalue ($CurState)"
    sqlite3 "$database_file" "UPDATE Menu_roms SET disp = '$disp_withvalue',pinyin = '$disp_withvalue',cpinyin = '$disp_withvalue',opinyin = '$disp_withvalue' WHERE path = '$path';"
    sqlite3 "$database_file" "UPDATE Menu_roms SET ppath = '$disp_withvalue' WHERE ppath = '$disp';"

    echo "==== Updated \"$disp_withoutvalue\" to \"$disp_withvalue\""
  done

	
    crc32 "$database_file"  | awk '{print $1}' >"$crc_DB_file"
    sync

else
    echo "CRC32 has not changed. No operations performed."
fi

cp /mnt/SDCARD/Apps/Scraper/GoTo_Scraper_List.json /tmp/state.json
sync
