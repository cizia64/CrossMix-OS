#!/bin/sh
echo $0 $*

silent=false
for arg in "$@"; do
    if [ "$arg" = "-s" ]; then
        silent=true
        break
    fi
done

create_temp_dir() {
    mkdir -p /mnt/SDCARD/Theme.temp
    for dir in /mnt/SDCARD/Themes/*/; do
        if [ -f "$dir/config.json" ]; then
            mv "$dir" /mnt/SDCARD/Theme.temp/
        fi
    done
}

read_and_store_labels() {
    temp_file="/mnt/SDCARD/temp_labels.txt"
    : >"$temp_file"

    for dir in /mnt/SDCARD/Theme.temp/*/; do
        if [ -f "$dir/config.json" ]; then
            label=$(awk -F'"' '/"name":/ {print $4}' "$dir/config.json")
            echo "$label:$dir" >>"$temp_file"
            echo "$label:$dir"
        fi
    done
}

sort_and_copy_back() {
    sort_order="$1"
    if [ "$sort_order" = "desc" ]; then
        sort_flag="-rf"
    else
        sort_flag="-f"
    fi

    sort $sort_flag "$temp_file" | while IFS=: read -r label dir; do
        mv "$dir" /mnt/SDCARD/Themes/
    done
}

cleanup() {
    rm -rf /mnt/SDCARD/Theme.temp
    rm "$temp_file"
    # Display a spash screen only if -s argument is not specified
    if [ "$silent" = false ]; then
        /mnt/SDCARD/System/bin/sdl2imgshow \
            -i "/mnt/SDCARD/trimui/res/crossmix-os/bg-info.png" \
            -f "/mnt/SDCARD/System/resources/DejaVuSans.ttf" \
            -s 50 \
            -c "220,220,220" \
            -t "Alphabetical sorting complete." &
        sleep 0.1
        pkill -f sdl2imgshow
    fi
}

main() {
    sort_order="${1:-asc}"
    create_temp_dir
    read_and_store_labels
    sort_and_copy_back "$sort_order"
    cleanup
}

main "$@"
