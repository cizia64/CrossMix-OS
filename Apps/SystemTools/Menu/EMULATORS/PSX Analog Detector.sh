#!/bin/sh

# Set CPU performance mode
echo performance >/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
echo 1416000 >/sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq

PATH="/mnt/SDCARD/System/bin:$PATH"
export LD_LIBRARY_PATH="/mnt/SDCARD/System/lib:$LD_LIBRARY_PATH"
RA_DIR="/mnt/SDCARD/RetroArch"
DB_NAME="/mnt/SDCARD/System/usr/trimui/scripts/Sony - PlayStation - analog/Sony - PlayStation - analog.db"
analog_count="/tmp/analog_count"
echo 0 >"$analog_count"

# Create necessary directories for remaps
mkdir -p "$RA_DIR/.retroarch/config/remaps/PCSX-ReARMed"
mkdir -p "$RA_DIR/.retroarch/config/remaps/DuckStation"
mkdir -p "$RA_DIR/.retroarch/config/remaps/SwanStation"

# Display an information image
/mnt/SDCARD/System/bin/sdl2imgshow \
  -i "/mnt/SDCARD/trimui/res/crossmix-os/bg-info.png" \
  -f "/mnt/SDCARD/System/resources/DejaVuSans.ttf" \
  -s 50 \
  -c "220,220,220" \
  -t "Detecting Dual Shock compatible games..." &

# Function to apply Dual Shock remaps
apply_dual_shock_remap() {
  local filename="$1"
  
  for system in "PCSX-ReARMed" "DuckStation" "SwanStation"; do
    local device_code="517"  # Default device code
    
    if [ "$system" = "DuckStation" ]; then
      device_code="5"
    fi
    
    local filepath="$RA_DIR/.retroarch/config/remaps/$system/$filename"
    
    echo "Applying Dual Shock to $filename for $system"
    
    # Apply remap
    if [ -e "$filepath" ]; then
      echo "input_libretro_device_p1 = \"$device_code\"" > "/tmp/$filename"
      /mnt/SDCARD/System/usr/trimui/scripts/patch_ra_cfg.sh "/tmp/$filename" "$filepath"
      rm "/tmp/$filename"
    else
      echo "input_libretro_device_p1 = \"$device_code\"" > "$filepath"
    fi
  done
}

# Step 1: Scan with RetroArch
echo "=================================================================="
echo "            Step 1: Scanning with RetroArch"
echo "=================================================================="
cd "$RA_DIR"
HOME="$RA_DIR/" "$RA_DIR/ra64.trimui" --appendconfig "/mnt/SDCARD/System/usr/trimui/scripts/Sony - PlayStation - analog/Sony - PlayStation - analog.cfg" --scan="/mnt/SDCARD/Roms/PS"
echo "---------------------------------"

# Traverse the "Sony - PlayStation - analog.lpl" playlist file with jq
/mnt/SDCARD/System/bin/jq -r '.items[] | .crc32, .label, .path' "$RA_DIR/.retroarch/playlists/Sony - PlayStation - analog.lpl" |
  while IFS= read -r crc32; do
    IFS= read -r label
    IFS= read -r path

    echo "Processing: $path"

    # Increment game count
    count=$(cat "$analog_count")
    count=$((count + 1))
    echo "$count" >"$analog_count"

    filename=$(basename "$path")
    filename="${filename%.*}.rmp"

    # Apply Dual Shock remaps
    apply_dual_shock_remap "$filename"

    echo "---------------------------------"
  done

rm "$RA_DIR/.retroarch/playlists/Sony - PlayStation - analog.lpl"

# Sync the filesystem
sync

# Step 2: Detection with Universal-PS-X-Serial-ID
echo "=================================================================="
echo "        Step 2: Detection with Universal-PS-X-Serial-ID"
echo "=================================================================="
find "/mnt/SDCARD/Roms/PS" -type f \( -iname "*.vcd" -o -iname "*.pbp" -o -iname "*.pkg" \) | while read romfile; do
  echo "Processing: $romfile"
  
  # Run the psx-serial command
  Serial=$(/mnt/SDCARD/System/bin/UPSX-ID "$romfile" -2)
  
  # Display the extracted Serial
  echo "Serial: $Serial"
  
  # Check if the Serial is in the database
  result=$(sqlite3 "$DB_NAME" "SELECT Name FROM games WHERE Serial = '$Serial'")
  
  # Apply remaps if a match is found
  if [ -n "$result" ]; then
    echo "Match found: $result"
    count=$(cat "$analog_count")
    count=$((count + 1))
    echo "$count" >"$analog_count"
    filename=$(basename "$romfile")
    filename="${filename%.*}.rmp"
    apply_dual_shock_remap "$filename"
  else
    echo "No match found"
  fi
  
  echo "---------------------------------"
done

# Step 3: Name-based detection
echo "=================================================================="
echo "               Step 3: Name-based detection"
echo "=================================================================="
find "/mnt/SDCARD/Roms/PS" -type f \( -iname "*.m3u" -o -iname "*.cue" -o -iname "*.bin" -o -iname "*.chd" -o -iname "*.vcd" -o -iname "*.pbp" -o -iname "*.pkg" \) | while read romfile; do
  echo "Processing: $romfile"
  romName=$(basename "$romfile")
  romNameNoExtension=${romName%.*}
  echo "romNameNoExtension: $romNameNoExtension"

  romNameTrimmed="${romNameNoExtension/".nkit"/}"
  romNameTrimmed="${romNameTrimmed//"!"/}"
  romNameTrimmed="${romNameTrimmed//"&"/}"
  romNameTrimmed="${romNameTrimmed/"Disc "/}"
  romNameTrimmed="${romNameTrimmed/"Rev "/}"
  romNameTrimmed="$(echo "$romNameTrimmed" | sed -e 's/ ([^()]*)//g' -e 's/ [[A-z0-9!+]*]//g' -e 's/([^()]*)//g' -e 's/[[A-z0-9!+]*]//g')"
  
  # Check if the Name is in the database
  result=$(sqlite3 "$DB_NAME" "SELECT Name FROM games WHERE Name = '$romNameNoExtension'")
  if ! [ -n "$result" ]; then
    echo "Try again with romNameTrimmed: $romNameTrimmed"
    result=$(sqlite3 "$DB_NAME" "SELECT Name FROM games WHERE Name LIKE '%$romNameTrimmed%' LIMIT 1")
  fi 
  
  # Apply remaps if a match is found
  if [ -n "$result" ]; then
    echo "Match found: $result"
    count=$(cat "$analog_count")
    count=$((count + 1))
    echo "$count" >"$analog_count"
    filename=$(basename "$romfile")
    filename="${filename%.*}.rmp"
    apply_dual_shock_remap "$filename"
  else
    echo "No match found"
  fi
  
  echo "---------------------------------"
done

# Step 4: M3U file detection
echo "=================================================================="
echo "               Step 4: M3U file detection"
echo "=================================================================="
find "/mnt/SDCARD/Roms/PS" -type f -iname "*.m3u" | while read m3ufile; do
  echo "Processing M3U: $m3ufile"
  remap_applied=false
  
  while IFS= read -r romfile; do
    romfile_path=$(dirname "$m3ufile")/"$romfile"
    filename=$(basename "$romfile_path")
    filename="${filename%.*}.rmp"
    # Check if a Dual Shock remap exists for this file
    if (grep -q "input_libretro_device_p1" "$RA_DIR/.retroarch/config/remaps/PCSX-ReARMed/$filename" 2>/dev/null); then
      remap_applied=true
      break
    fi
  done < "$m3ufile"
  
  if [ "$remap_applied" = true ]; then
    m3u_filename=$(basename "$m3ufile")
    m3u_filename="${m3u_filename%.*}.rmp"
    apply_dual_shock_remap "$m3u_filename"
  fi
  
  echo "---------------------------------"
done

echo "Number of successful path finds: $(cat "$analog_count")"

# Display the number of compatible games detected
pkill -f sdl2imgshow
sleep 0.3
/mnt/SDCARD/System/bin/sdl2imgshow \
  -i "/mnt/SDCARD/trimui/res/crossmix-os/bg-info.png" \
  -f "/mnt/SDCARD/System/resources/DejaVuSans.ttf" \
  -s 50 \
  -c "220,220,220" \
  -t "$(cat "$analog_count") analog compatible game(s) detected." &

sleep 4
pkill -f sdl2imgshow
rm "$analog_count"
