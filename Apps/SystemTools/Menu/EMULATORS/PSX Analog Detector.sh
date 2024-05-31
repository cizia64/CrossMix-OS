#!/bin/sh
echo performance >/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
echo 1416000 >/sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq

RA_DIR=/mnt/SDCARD/RetroArch
cd $RA_DIR
HOME=$RA_DIR/ $RA_DIR/ra64.trimui --scan=/mnt/SDCARD/Roms/PS
analog_count="/tmp/analog_count"
echo 0 >"$analog_count"

/mnt/SDCARD/System/bin/sdl2imgshow \
  -i "/mnt/SDCARD/trimui/res/crossmix-os/bg-info.png" \
  -f "/mnt/SDCARD/System/resources/DejaVuSans.ttf" \
  -s 50 \
  -c "220,220,220" \
  -t "Detecting Dual Shock compatible games..." &

# Traverse the "Sony - PlayStation.lpl" file with jq
/mnt/SDCARD/System/bin/jq -r '.items[] | .crc32, .label, .path' "/mnt/SDCARD/RetroArch/.retroarch/playlists/Sony - PlayStation.lpl" |
  while IFS= read -r crc32; do
    IFS= read -r label
    IFS= read -r path

    # Extract CRC32
    crc32=$(echo "$crc32" | awk -F '|' '{print $1}')

    # Search for CRC32 in psx_analog_gamelist.dat
    found_path=$(grep -E "$crc32" "/mnt/SDCARD/System/usr/trimui/scripts/psx_analog_gamelist.dat")

    # If path is found, create the file with .rmp extension
    if [ -n "$found_path" ]; then
      # Create file path with .rmp extension
      count=$(cat "$analog_count")
      count=$((count + 1))
      echo "$count" >"$analog_count"
      filename=$(basename "$path")
      filename="${filename%.*}.rmp"
      # ========= PCSX-ReARMed
      filepath="/mnt/SDCARD/RetroArch/.retroarch/config/remaps/PCSX-ReARMed/$filename"
      echo "Applying Dual Shock to $filename for PCSX-ReARMed"
      if [ -e "$filepath" ]; then
        configPatchFile="/tmp/$filename"
        echo 'input_libretro_device_p1 = "517"' >"$configPatchFile"
        /mnt/SDCARD/System/usr/trimui/scripts/patch_ra_cfg.sh "$configPatchFile" "$filepath"
        rm "$configPatchFile"
      else
        # Write content to the file
        echo 'input_libretro_device_p1 = "517"' >"$filepath"
      fi
      # ========= Duckstation
      filepath="/mnt/SDCARD/RetroArch/.retroarch/config/remaps/DuckStation/$filename"
      echo "Applying Dual Shock to $filename for PCSX-ReARMed"
      if [ -e "$filepath" ]; then
        configPatchFile="/tmp/$filename"
        echo 'input_libretro_device_p1 = "5"' >"$configPatchFile"
        /mnt/SDCARD/System/usr/trimui/scripts/patch_ra_cfg.sh "$configPatchFile" "$filepath"
        rm "$configPatchFile"
      else
        # Write content to the file
        echo 'input_libretro_device_p1 = "5"' >"$filepath"
      fi
      # ========= Swantation
      filepath="/mnt/SDCARD/RetroArch/.retroarch/config/remaps/PCSX-ReARMed/$filename"
      echo "Applying Dual Shock to $filename for PCSX-ReARMed"
      if [ -e "$filepath" ]; then
        configPatchFile="/tmp/$filename"
        echo 'input_libretro_device_p1 = "517"' >"$configPatchFile"
        /mnt/SDCARD/System/usr/trimui/scripts/patch_ra_cfg.sh "$configPatchFile" "$filepath"
        rm "$configPatchFile"
      else
        # Write content to the file
        echo 'input_libretro_device_p1 = "517"' >"$filepath"
      fi
    fi
  done
sync

echo "Number of successful path finds: $(cat "$analog_count")"

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
