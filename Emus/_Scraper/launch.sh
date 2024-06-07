#!/bin/sh
echo $0 $*

echo "Scraping target: $1"
log_file="/tmp/scraper.log"

# Launch the scraping task in the background
cd "/mnt/SDCARD/Roms/$1"
HOME=/mnt/SDCARD/Apps/Scraper/ /mnt/SDCARD/System/bin/scraper -img_workers 3 -refresh -thumb_only -img_format png -download_images -image_suffix "" -image_dir="/mnt/SDCARD/Imgs/$1" -max_height 500 -max_width 400 -output_file "/mnt/SDCARD/Imgs/$1/gamelist.xml" &> "$log_file" &


"/mnt/SDCARD/System/usr/trimui/scripts/getkey.sh" B &

# Check if the scraping process is running
scraping_running() {
    pgrep -f "scraper" >/dev/null
}

while scraping_running; do

    if ! pgrep "getkey" >/dev/null; then
        pkill scraper
    fi

    info_count=$(grep -c "INFO: Starting:" "$log_file")
    error_count=$(grep -c "ERR: error processing" "$log_file")

    /mnt/SDCARD/System/bin/sdl2imgshow \
        -i "/mnt/SDCARD/trimui/res/crossmix-os/bg-stop-exit.png" \
        -f "/mnt/SDCARD/System/resources/DejaVuSans.ttf" \
        -s 30 \
        -c "220,220,220" \
        -t "Files processed: $info_count, Not found: $error_count" &
    sleep 1
    pkill -f sdl2imgshow
    sleep 2.5
done

pkill getkey
info_count=$(grep -c "INFO: Starting:" "$log_file")
error_count=$(grep -c "ERR: error processing" "$log_file")

/mnt/SDCARD/System/bin/sdl2imgshow \
    -i "/mnt/SDCARD/trimui/res/crossmix-os/bg-info.png" \
    -f "/mnt/SDCARD/System/resources/DejaVuSans.ttf" \
    -s 30 \
    -c "220,220,220" \
    -t "Scraping finished: Files processed: $info_count, Not found: $error_count" &
sleep 1
pkill -f sdl2imgshow

sleep 1
sleep 2

# Remove the first line from the recentlist.json file
recentlist="/mnt/SDCARD/Roms/recentlist.json"
sed -i '1d' "$recentlist"
sync
