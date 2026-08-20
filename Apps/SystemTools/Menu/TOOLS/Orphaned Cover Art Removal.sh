#!/bin/sh

button=$(/mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "This may take a significant amount of time. Press X to Proceed. Press B to Quit." -fs 28 -k "X B MENU")

if [ "$button" = "X" ]; then
    /mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "Removing orphaned cover art... Please wait."

    cd /mnt/SDCARD/ || exit 1

    total_count_file=$(mktemp) && echo 0 > "$total_count_file"
    deleted_count_file=$(mktemp) && echo 0 > "$deleted_count_file"

    find "Imgs" -type f -name "*.png" -print0 | while IFS= read -r -d '' img_file; do
        echo "$(expr $(cat "$total_count_file") + 1)" > "$total_count_file"

        relative_path=$(echo "$img_file" | sed "s|^Imgs/||")
        img_folder=$(dirname "$relative_path")
        img_name=$(basename "$relative_path" .png)

        if ! find "Roms/$img_folder" -type f -name "$(printf "%s\n" "$img_name" | sed 's/[][\*\?]/\\&/g').*" | grep -q .; then
            rm "$img_file"
            echo "$(expr $(cat "$deleted_count_file") + 1)" > "$deleted_count_file"
        fi
    done

    total_count=$(cat "$total_count_file")
    deleted_count=$(cat "$deleted_count_file")
    rm "$total_count_file" "$deleted_count_file"

    /mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "Removed $deleted_count orphaned cover images. Total images scanned: $total_count." -t 3
fi
