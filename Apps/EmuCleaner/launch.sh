#!/bin/sh
PATH="/mnt/SDCARD/System/bin:$PATH"
export LD_LIBRARY_PATH="/mnt/SDCARD/System/lib:/usr/trimui/lib:$LD_LIBRARY_PATH"

# Configuring CPU performance
echo performance >/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
echo 1416000 >/sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq

silent=false
for arg in "$@"; do
  if [ "$arg" = "-s" ]; then
    silent=true
    break
  fi
done

EmuCleanerPath="$(dirname "$0")/"
EmuFolder="/mnt/SDCARD/Emus"
json_file="/mnt/SDCARD/Emus/show.json"

NumRemoved=0
NumAdded=0

if [ "$silent" = false ]; then
  /mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -i "$EmuCleanerPath/background.jpg"
fi

# Initialize an empty string to store JSON entries
json_entries=""

write_entry() {
  local label="$1"
  local show="$2"
  entry=$(printf '{"label": "%s", "show": %d},' "$label" "$show")
  json_entries="$json_entries$entry"
}

# Check if some emulators must be hidden from /mnt/SDCARD/Emus
for subfolder in "$EmuFolder"/*/; do
  # Skip folders that start with an underscore

  if [ -f "$subfolder/config.json" ]; then
    # Retrieve multiple values with a single jq command
    IFS="|" read -r rompath label extlist <<EOF
$(jq -r '. | "\(.rompath)|\(.label)|\(.extlist)"' "$subfolder/config.json")
EOF

    # Convert rompath to an absolute path if it is relative
    case "$rompath" in
    /*) # Absolute path, use as is
      RomPath="$rompath"
      ;;
    *) # Relative path, convert to absolute
      RomPath=$(realpath "$subfolder/$rompath")
      ;;
    esac

    subfolder_name="$(basename "$subfolder")"
    if [ "$(echo "$subfolder_name" | cut -c1)" = "_" ]; then
      echo "Removing $label emulator (!! Exception for \"$subfolder_name\" !!)."
      write_entry "$label" 0
      continue
    fi

    # Construct the find command based on extlist
    if [ -z "$extlist" ] || [ "$extlist" = "null" ]; then
      find_cmd="find \"$RomPath\" -type f ! -name '*.db' ! -name '.gitkeep' ! -name '*.launch' -mindepth 1 -maxdepth 2"
    else
      exts=$(echo "$extlist" | tr '|' ' ')
      find_cmd="find \"$RomPath\" -type f \( $(printf " -iname '*.%s' -o" $exts | sed 's/ -o$//') \) ! -name '*.launch' -mindepth 1 -maxdepth 2"
    fi

    if eval "$find_cmd -print -quit" | grep -q .; then
      echo "Adding $label emulator (roms found in \"$subfolder_name\" folder)."
      write_entry "$label" 1
      NumAdded=$((NumAdded + 1))
    else
      echo "Removing $label emulator (!! no roms in \"$subfolder_name\" folder !!)."
      write_entry "$label" 0
      NumRemoved=$((NumRemoved + 1))
    fi
  fi
done

# Remove the trailing comma and format with jq
json_content=$(echo "[${json_entries%,}]" | jq '.')

echo "$json_content" >"$json_file"
sync

if [ "$silent" = false ]; then
  jq '(.list[].tabstate[] | select(has("pagestart"))).pagestart = 0 | (.list[].tabstate[] | select(has("pageend"))).pageend = 7' /tmp/state.json >/tmp/state.tmp && mv /tmp/state.tmp /tmp/state.json
fi

sync

echo -ne "\n=============================\n"
echo -ne "${NumAdded} displayed emulator(s)\n${NumRemoved} hidden emulator(s)\n"
echo -ne "=============================\n\n"

if [ "$silent" = false ]; then
  /mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -i "$EmuCleanerPath/background-info.jpg" -m "${NumAdded} displayed emulator(s).      ${NumRemoved} hidden emulator(s)." -t 2.5
fi
