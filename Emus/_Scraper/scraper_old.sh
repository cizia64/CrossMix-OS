#!/bin/sh
echo $0 $*

PATH="/mnt/SDCARD/System/bin:$PATH"

echo "Scraping target: $1"
log_file="/mnt/SDCARD/Apps/Scraper/scraper.log"


if pgrep -f "/mnt/SDCARD/System/bin/scraper" > /dev/null; then
    /mnt/SDCARD/System/bin/sdl2imgshow \
        -i "/mnt/SDCARD/trimui/res/crossmix-os/bg-stop-exit.png" \
        -f "/mnt/SDCARD/System/resources/DejaVuSans.ttf" \
        -s 30 \
        -c "220,220,220" \
        -t "A scraping task is already running in background." &

    sleep 1
    pkill -f sdl2imgshow
    sleep 2
    exit
fi


ScraperConfigFile=/mnt/SDCARD/System/etc/scraper.json
if [ -f "$ScraperConfigFile" ]; then
	config=$(cat $ScraperConfigFile)
	MediaType=$(echo "$config" | jq -r '.Screenscraper_MediaType')
	
	if [ "$MediaType" != "box-2D" ]; then
		echo "MediaType is not box-2D, it is $MediaType"
		/mnt/SDCARD/System/bin/text_viewer  -y -f 30 -m "You have selected $MediaType for screenscraper.\nThis scraper only supports 2D box!\n\nAre you sure that you want to scrap 2D box with the old scraper ?\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n                                         Press START to validate your choice."
		if [ $? -eq 21 ]; then
			echo "yes, box-2D scraping launch."
		else
			echo "no, box-2D scraping aborted."
			exit
		fi
	fi
fi

# Launch the scraping task in the background
cd "/mnt/SDCARD/Roms/$1"
HOME=/mnt/SDCARD/Apps/Scraper/ /mnt/SDCARD/System/bin/scraper -img_workers 3 -refresh -thumb_only -img_format png -download_images -image_suffix "" -image_dir="/mnt/SDCARD/Imgs/$1" -max_height 500 -max_width 400 -output_file "/mnt/SDCARD/Imgs/$1/gamelist.xml" &> "$log_file" &
SCRAP_PID=$!


# ==== If enabled, launch the scraping task in the background ====


if [ -f "$ScraperConfigFile" ]; then
	config=$(cat $ScraperConfigFile)
	ScrapeInBackground=$(echo "$config" | jq -r '.ScrapeInBackground')
	if [ "$ScrapeInBackground" = "true" ]; then

		play_sound_after_scraping() {
			while kill -0 $1 2>/dev/null; do
				sleep 1
			done
			aplay /mnt/SDCARD/trimui/res/sound/Background\ Scraping\ Finished.wav
		}


		play_sound_after_scraping $SCRAP_PID &

		/mnt/SDCARD/System/bin/sdl2imgshow \
			-i "/mnt/SDCARD/trimui/res/crossmix-os/bg-stop-exit.png" \
			-f "/mnt/SDCARD/System/resources/DejaVuSans.ttf" \
			-s 30 \
			-c "220,220,220" \
			-t "$1 scraping launched in background." &
		sleep 1
		pkill -f sdl2imgshow
		sleep 2
		exit
	fi
fi
# ================================================================




"/mnt/SDCARD/System/usr/trimui/scripts/getkey.sh" B &

# Check if the scraping process is running
scraping_running() {
    pgrep -f "/mnt/SDCARD/System/bin/scraper" >/dev/null
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

# we exit getkey.sh script (and its child evtest processes)
for pid in $(pgrep -f getkey.sh); do pkill -TERM -P $pid; done

info_count=$(grep -c "INFO: Starting:" "$log_file")
error_count=$(grep -c "ERR: error processing" "$log_file")
pkill -f sdl2imgshow
sleep 1
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
