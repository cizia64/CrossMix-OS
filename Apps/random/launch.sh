#!/bin/sh

PATH="/mnt/SDCARD/System/bin:$PATH"
export LD_LIBRARY_PATH="/mnt/SDCARD/System/lib:/usr/trimui/lib:$LD_LIBRARY_PATH"

# Function to choose a random database
choose_random_db() {
  find /mnt/SDCARD/Roms -mindepth 1 -maxdepth 2 -type f -name '*_cache7.db' ! -path '*/_*/*' ! -path '*/MUSIC/*' ! -path '*/VIDEOS/*' | shuf -n 1
}

# Function to extract the table prefix from the database path
get_table_prefix() {
  db_path=$1
  basename $(dirname "$db_path")
}

# Function to choose a random game from a database
choose_random_game() {
  db=$1
  table_prefix=$2
  table_name="${table_prefix}_roms"
  sqlite3 "$db" "SELECT disp, path, imgpath FROM $table_name WHERE path NOT LIKE '%.launch' ORDER BY RANDOM() LIMIT 1;"
}

add_line_to_recentlist() {
  # Parameters
  disp="$1"
  path="$2"
  imgpath="$3"
  launchpath="$4"

  # Construct the JSON object
  json_line=$(jq -nc --arg disp "$disp" --arg path "$path" --arg imgpath "$imgpath" --arg launch "$launchpath" --argjson type 23 '{ "label": $disp, "rompath": $path, "imgpath": $imgpath, "launch": $launch, "type": $type }')

  # Remove the line if the rompath already exists in recentlist.json
  grep -v "$path" "/mnt/SDCARD/Roms/recentlist.json" >temp
  echo "$json_line" | cat - temp >"/mnt/SDCARD/Roms/recentlist.json"
  rm temp
  sync

}

# Main function
main() {
  if [ -f "./random_manual.png" ]; then
    /mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -i "./random_manual.png" -k " "
    mv ./random_manual.png ./random_manual_done.png
  fi
  presented_games_file="/tmp/presented_games.txt"
  consecutive_misses=0

  while true; do
    # Choose a random database
    db=$(choose_random_db)

    # Extract the table prefix
    table_prefix=$(get_table_prefix "$db")

    # Choose a random game from the database
    game_info=$(choose_random_game "$db" "$table_prefix")
    disp=$(echo "$game_info" | cut -d'|' -f1)
    path=$(echo "$game_info" | cut -d'|' -f2)
    imgpath=$(echo "$game_info" | cut -d'|' -f3)

    # Check if the game file exists
    if [ -f "$path" ]; then
      # Display game information
      echo "Game name: $disp"
      echo "Game path: $path"
      echo "Image path: $imgpath"

      # Check if the game has already been presented
      if ! grep -q "$path" "$presented_games_file"; then
        echo "$path" >>"$presented_games_file"

        if ! [ -f "$imgpath" ]; then
          imgtodisplay="/usr/trimui/res/skin/ic-game-580.png"
        else
          imgtodisplay="$imgpath"
        fi

        button=$(/mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -i "$imgtodisplay" -c "122,122,122" -m "${disp}" -k "A B X MENU")

        if [ "$button" = "A" ]; then
          echo "Okay, launching the game: $disp"

          launcher=$(jq -r '.launch' "/mnt/SDCARD/Emus/$table_prefix/config.json")
          launchpath="/mnt/SDCARD/Emus/$table_prefix/$launcher"

          add_line_to_recentlist "$disp" "$path" "$imgpath" "$launchpath"

          "$launchpath" "$path"

          exit 0
        elif [ "$button" = "B" ] || [ "$button" = "MENU" ]; then
          /mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -c "122,122,122" -m "Exiting"
          exit 0
        fi

        consecutive_misses=0 # Reset consecutive misses counter
      else
        consecutive_misses=$((consecutive_misses + 1))
      fi

      if [ $consecutive_misses -ge 5 ]; then
        echo "*** Five consecutive misses detected. Clearing the presented games file."
        >"$presented_games_file" # Clear the presented games file
        consecutive_misses=0     # Reset consecutive misses counter
      fi
    fi
  done
}

main
