#!/bin/sh
Current_FW_Revision=$(grep 'DISTRIB_DESCRIPTION' /etc/openwrt_release | cut -d '.' -f 3)

read -r Current_device </etc/trimui_device.txt

if [ "$Current_device" = "tsp" ]; then

    if [ "$Current_FW_Revision" -gt "20240413" ] && [ "$Current_FW_Revision" -lt "20250505" ]; then # on firmware hotfix 9 there is less space than before on /dev/mmcblk0p1 so we avoid to flash the logo
        /mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "Not compatible with firmware superior to v1.0.4 hotfix 6." -t 3
        exit 1
    fi
    src_dir="/mnt/SDCARD/Apps/BootLogo/Images_1280x720/"
else
    src_dir="/mnt/SDCARD/Apps/BootLogo/Images_1024x768/"
fi

echo performance >/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
echo 1416000 >/sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq

LD_LIBRARY_PATH="/mnt/SDCARD/System/lib:/usr/trimui/lib:$LD_LIBRARY_PATH"

rm -f ./GoBackTo_Apps.json
cp /tmp/state.json ./GoBackTo_Apps.json
cp ./GoTo_Bootlogo_List.json /tmp/state.json

dest_dir="/mnt/SDCARD/Apps/BootLogo/Thumbnails/"
find "$dest_dir" -type f -not -name "- Default Trimui.png" -exec rm -f {} \;
sync

/mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "Generating thumbnails..." -fs 50

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

rm -f "$dest_dir/Thumbnails_cache7.db"
echo "All conversions have been made."

sync
exit
