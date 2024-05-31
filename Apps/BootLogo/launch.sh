#!/bin/sh

echo performance >/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
echo 1416000 >/sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq

LD_LIBRARY_PATH="/mnt/SDCARD/System/lib:/usr/trimui/lib:$LD_LIBRARY_PATH"

rm -f ./GoBackTo_Apps.json
cp /tmp/state.json ./GoBackTo_Apps.json
cp ./GoTo_Bootlogo_List.json /tmp/state.json


src_dir="/mnt/SDCARD/Apps/BootLogo/Images/"
dest_dir="/mnt/SDCARD/Apps/BootLogo/Thumbnails/"
find "$dest_dir" -type f -not -name "- Default Trimui.png" -exec rm -f {} \;
sync


/mnt/SDCARD/System/bin/sdl2imgshow \
  -i "/mnt/SDCARD/trimui/res/crossmix-os/bg-info.png" \
  -f "/mnt/SDCARD/System/resources/DejaVuSans.ttf" \
  -s 50  \
  -c "220,220,220" \
  -t "Generating thumbnails..." &
  sleep 0.3
  pkill -f sdl2imgshow


# Rename files to start with a capital letter
find "$src_dir" -type f -iname "*.bmp" | while read -r bmp_file; do
    filename=$(basename "$bmp_file")
    dirname=$(dirname "$bmp_file")
    new_filename="$(echo "$filename" | awk '{print toupper(substr($0,1,1)) substr($0,2)}')"
	# Lowercase extension
	new_filename="$(echo "$new_filename" | sed 's/\.BMP$/.bmp/I')"  
	# replace underscores by spaces
	# new_filename="$(echo "$new_filename" | sed 's/_/ /g')"
    mv "$bmp_file" "$dirname/$new_filename"
done
sync

# Create thumbnails
find "$src_dir" -type f -iname "*.bmp" | while read -r bmp_file; do
    filename=$(basename "$bmp_file")
    if [ "$filename" != "- Default Trimui.bmp" ]; then
        png_dest="$dest_dir${filename%.bmp}.png"
        /mnt/SDCARD/System/bin/gm convert "$bmp_file" -resize 300x\> "$png_dest"
    fi
done
sync

rm -f "/mnt/SDCARD/Apps/BootLogo/Thumbnails/Thumbnails_cache7.db"
echo "All conversions have been made."


sync
exit

