#!/bin/sh
echo $0 $*

echo performance >/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
echo 1416000 >/sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq

PATH="/mnt/SDCARD/System/bin:$PATH"
export LD_LIBRARY_PATH="/mnt/SDCARD/System/lib:/usr/trimui/lib:$LD_LIBRARY_PATH"
database_file="/mnt/SDCARD/Apps/SystemTools/Menu/Menu_cache7.db"
CurrentTheme=$(/mnt/SDCARD/System/bin/jq -r .theme /mnt/UDISK/system.json)
CrossMix_Style=$(/mnt/SDCARD/System/bin/jq -r '.["CROSSMIX STYLE"]' "/mnt/SDCARD/System/etc/crossmix.json")
mkdir -p /mnt/SDCARD/System/starts/
mkdir -p /mnt/SDCARD/System/etc
read -r current_device </etc/trimui_device.txt
if [ ! -f "/mnt/SDCARD/System/etc/crossmix.json" ]; then
  touch "/mnt/SDCARD/System/etc/crossmix.json"
fi
sync

####################################### For testing :
# rm "$database_file"
#######################################

rebuildmenu=false
for arg in "$@"; do
  if [ "$arg" = "-rebuildmenu" ]; then
    rebuildmenu=true
    break
  fi
done

if [ "$rebuildmenu" = true ]; then
  rm "$database_file"
  sync
  LaunchMessage="Building Menu..."
else

  if [ -f "$database_file" ]; then

    contains_hashes=$(sqlite3 "$database_file" "SELECT COUNT(*) FROM Menu_roms WHERE disp LIKE '%##%';")
    # If any 'disp' field contains '##', delete the database
    if [ "$contains_hashes" -gt 0 ]; then
      rm -f "$database_file"
      echo "Corrupted System Tools database, re-building..."
      LaunchMessage="Re-Building Menu..."
    else
      LaunchMessage="Loading..."
    fi
  else
    LaunchMessage="Building Menu..."
  fi

fi

/mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "$LaunchMessage"

cp /mnt/SDCARD/Apps/SystemTools/GoTo_SystemTools_List.json /tmp/state.json

# We re-create the database only if it doesn't exist...
if [ -f "$database_file" ]; then
  exit
fi

if [ -d "/mnt/SDCARD/Apps/SystemTools/Menu/Imgs_$CrossMix_Style" ]; then
  img_path="/mnt/SDCARD/Apps/SystemTools/Menu/Imgs_$CrossMix_Style"
else
  img_path="/mnt/SDCARD/Apps/SystemTools/Menu/Imgs"
fi

# =========================================== Populate icons, backgrounds and themes sets ============================================

# We remove dot files from Mac OS
find /mnt/SDCARD/Apps/SystemTools -name '._*' -exec rm '{}' \;

BG_list_directory="/mnt/SDCARD/Apps/SystemTools/Menu/ADVANCED SETTINGS##BACKGROUNDS (value)/"
BG_imgs_directory="${img_path}/ADVANCED SETTINGS##BACKGROUNDS (value)/"
# Cleaning old list
find "$BG_list_directory" -type f -name "*.sh" ! -name "Default.sh" -exec rm {} +
rm "$BG_imgs_directory"/*.png

for subdir in /mnt/SDCARD/Backgrounds/*/; do
  subdir_name=$(basename "$subdir")
  cp "${BG_list_directory}Default.sh" "${BG_list_directory}${subdir_name}.sh"

  # Check if preview.png file exists

  if [ -f "${subdir}preview_$CrossMix_Style.png" ]; then
    # Copy themed preview_$CrossMix_Style.png with subfolder name
    cp "${subdir}preview_$CrossMix_Style.png" "${BG_imgs_directory}${subdir_name}.png"
  elif [ -f "${subdir}preview.png" ]; then
    # Copy preview.png with subfolder name
    cp "${subdir}preview.png" "${BG_imgs_directory}${subdir_name}.png"
  else
    # Check if the file SFC.png exists
    if [ -f "${subdir}SFC.png" ]; then
      cp "${subdir}SFC.png" "${BG_imgs_directory}${subdir_name}.png"
    else
      # If SFC.png doesn't exist, copy the first .png file found into ${subdir}Emus/.
      echo "----------------- ${subdir}"
      first_png=$(find "${subdir}" -maxdepth 2 -type f -name "*.png" | head -n 1)
      if [ -n "$first_png" ]; then
        cp "$first_png" "${BG_imgs_directory}${subdir_name}.png"
      fi
    fi
  fi

done

ICON_list_directory="/mnt/SDCARD/Apps/SystemTools/Menu/ADVANCED SETTINGS##ICONS (value)/"
ICON_imgs_directory="${img_path}/ADVANCED SETTINGS##ICONS (value)/"
# Cleaning old list
find "$ICON_list_directory" -type f -name "*.sh" ! -name "Default.sh" -exec rm {} +
rm "$ICON_imgs_directory"/*.png
for subdir in /mnt/SDCARD/Icons/*/; do
  subdir_name=$(basename "$subdir")
  cp "${ICON_list_directory}Default.sh" "${ICON_list_directory}${subdir_name}.sh"
  # Check if preview.png file exists
  if [ -f "${subdir}preview_$CrossMix_Style.png" ]; then
    # Copy preview.png with subfolder name
    cp "${subdir}preview.png" "${ICON_imgs_directory}${subdir_name}.png"
  elif [ -f "${subdir}preview.png" ]; then
    # Copy preview.png with subfolder name
    cp "${subdir}preview.png" "${ICON_imgs_directory}${subdir_name}.png"
  else
    # Check if the file SFC.png exists
    if [ -f "${subdir}Emus/SFC.png" ]; then
      cp "${subdir}Emus/SFC.png" "${ICON_imgs_directory}${subdir_name}.png"
    else
      # If SFC.png doesn't exist, copy the first .png file found into ${subdir}Emus/.
      first_png=$(find "${subdir}Emus/" -maxdepth 2 -type f -name "*.png" | head -n 1)
      if [ -n "$first_png" ]; then
        cp "$first_png" "${ICON_imgs_directory}${subdir_name}.png"
      fi
    fi
  fi
done

THEME_list_directory="/mnt/SDCARD/Apps/SystemTools/Menu/ADVANCED SETTINGS##THEMES (value)/"
THEME_imgs_directory="${img_path}/ADVANCED SETTINGS##THEMES (value)/"
# Cleaning old list
find "$THEME_list_directory" -type f -name "*.sh" ! -name "Default.sh" -exec rm {} +
rm "$THEME_imgs_directory"/*.png
for subdir in /mnt/SDCARD/Themes/*/; do
  subdir_name=$(basename "$subdir")

  # Check if preview.png file exists
  if [ -f "${subdir}preview_$CrossMix_Style.png" ]; then
    # Copy preview.png with subfolder name
    cp "${subdir}preview_$CrossMix_Style.png" "${THEME_imgs_directory}${subdir_name}.png"
  elif [ -f "${subdir}preview.png" ]; then
    # Copy preview.png with subfolder name
    cp "${subdir}preview.png" "${THEME_imgs_directory}${subdir_name}.png"
  else
    cp "${subdir}/bg.png" "${THEME_imgs_directory}${subdir_name}.png"
  fi

  if [ "$subdir_name" = "CrossMix - OS" ]; then
    mv "${THEME_imgs_directory}${subdir_name}.png" "${THEME_imgs_directory}Default.png"
    continue
  fi
  cp "${THEME_list_directory}Default.sh" "${THEME_list_directory}${subdir_name}.sh"

done

sync
# ==================================================== Create a new database file ====================================================

sqlite3 "$database_file" "CREATE TABLE Menu_roms (id INTEGER PRIMARY KEY, disp TEXT, path TEXT, imgpath TEXT, type INTEGER, ppath TEXT, pinyin TEXT, cpinyin TEXT, opinyin TEXT);"
sync

# ================================================= Create folders items in database =================================================
# Scan files in the rompath directory
search_path="/mnt/SDCARD/Apps/SystemTools/Menu/"

for folder in "$search_path"/*/; do
  if ! [ -f "$folder/.no_$current_device" ]; then
    # Extract the folder name
    folder_name=$(basename "$folder")

    # Check if the folder starts with "Imgs" directory
    if [ "${folder_name#Imgs}" != "$folder_name" ]; then
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
  fi
done

# ================================================= Create script items in database =================================================

# find "$search_path" -mindepth 1 -maxdepth 2 -type f | while read -r file; do
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

  if ! [ -f "$subfolder/.${filename_without_ext}.no_$current_device" ]; then

    if [ "${subfolder%/}" = "${search_path%/}" ]; then
      ppath="."
    else
      ppath="${subfolder##*/}"
    fi

    # Set the imgpath with the subfolder "Imgs"
    imgpath="$img_path/$(basename "$subfolder")/${filename%.*}.png"

    # Prepare the SQLite query with double quotes around the filename, ppath, and imgpath
    query="INSERT INTO Menu_roms (disp, path, imgpath, type, ppath, pinyin, cpinyin, opinyin) VALUES (\"$escaped_filename\", \"$file\", \"$imgpath\", 0, \"$ppath\", \"$escaped_filename\", \"$escaped_filename\", \"$escaped_filename\")"

    # Execute the query using sqlite3
    sqlite3 "$database_file" "$query"
    sync

    echo "Entry created for file: $file"
  fi
done

sync
# ================================================= Create subfolders hierarchy in database =================================================

echo "database_file= $database_file"

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

# ============================================== Modify folders which requires a "state" value ==============================================
echo "================"
# Get current state of the option
sqlite3 "$database_file" "SELECT disp, path FROM Menu_roms WHERE type = 1 AND disp LIKE '% (state)' ;" |
  while IFS='|' read -r disp path; do
    disp_withoutstate=$(echo "$disp" | sed 's/ (state)//g')
    CurState=$(jq -r --arg disp "$disp_withoutstate" '.[$disp]' "/mnt/SDCARD/System/etc/crossmix.json")
    if [ -z "$CurState" ] || [ "$CurState" = "null" ]; then
      CurState="not set"
    fi
    # ----------------------------------------------------------------------
    # Managing some exceptions : state values related to the current theme :
    if [ "$disp_withoutstate" = "CLICK" ]; then
      if [ -e "$CurrentTheme/sound/click.wav" ]; then
        CurState=1
      elif [ -e "$CurrentTheme/sound/click-off.wav" ]; then
        CurState=0
      else
        CurState="not av."
      fi
    fi
    if [ "$disp_withoutstate" = "MUSIC" ]; then
      if [ -e "$CurrentTheme/sound/bgm.mp3" ]; then
        CurState=1
      elif [ -e "$CurrentTheme/sound/bgm-off.mp3" ]; then
        CurState=0
      else
        CurState="not av."
      fi
    fi
    if [ "$disp_withoutstate" = "TOP LEFT LOGO" ]; then
      if [ -e "$CurrentTheme/skin/nav-logo-off.png" ]; then
        CurState=0
      else
        CurState=1
      fi
    fi
    # ----------------------------------------------------------------------

    if [ "$CurState" -eq 1 ]; then
      disp_withstate="$disp_withoutstate (enabled)"
    else
      disp_withstate="$disp_withoutstate (disabled)"
    fi

    sqlite3 "$database_file" "UPDATE Menu_roms SET disp = '$disp_withstate',pinyin = '$disp_withstate',cpinyin = '$disp_withstate',opinyin = '$disp_withstate'  WHERE path = '$path';"
    sqlite3 "$database_file" "UPDATE Menu_roms SET ppath = '$disp_withstate' WHERE ppath = '$disp';"

    echo "==== Updated \"$disp_withoutstate\" to \"$disp_withstate\""
  done

# ============================================== Modify folders which requires a "value" value ==============================================

sqlite3 "$database_file" "SELECT disp, path FROM Menu_roms WHERE type = 1 AND disp LIKE '% (value)' ;" |
  while IFS='|' read -r disp path; do
    disp_withoutvalue=$(echo "$disp" | sed 's/ (value)//g')
    if [ "$disp_withoutvalue" = "THEMES" ]; then
      CurState=$(basename "$CurrentTheme")
    else
      CurState=$(jq -r --arg disp "$disp_withoutvalue" '.[$disp] // "Default"' "/mnt/SDCARD/System/etc/crossmix.json")
    fi

    if [ -z "$CurState" ]; then
      CurState="not set"
    fi
    disp_withvalue="$disp_withoutvalue ($CurState)"
    sqlite3 "$database_file" "UPDATE Menu_roms SET disp = '$disp_withvalue',pinyin = '$disp_withvalue',cpinyin = '$disp_withvalue',opinyin = '$disp_withvalue' WHERE path = '$path';"
    sqlite3 "$database_file" "UPDATE Menu_roms SET ppath = '$disp_withvalue' WHERE ppath = '$disp';"

    echo "==== Updated \"$disp_withoutvalue\" to \"$disp_withvalue\""
  done

sync
