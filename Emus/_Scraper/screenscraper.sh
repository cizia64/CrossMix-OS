#!/bin/sh
echo $0 $*

PATH="/mnt/SDCARD/System/bin:$PATH"

file_extension="${1##*.}"
if [ "$file_extension" = "sh" ]; then
	"$1"
	exit 0
fi

echo "Scraping target: $1"
log_file="/mnt/SDCARD/Apps/Scraper/scraper.log"

# ==== If enabled, launch the scraping task in the background ====

ScraperConfigFile=/mnt/SDCARD/System/etc/scraper.json
if [ -f "$ScraperConfigFile" ]; then
	config=$(cat $ScraperConfigFile)
	ScrapeInBackground=$(echo "$config" | jq -r '.ScrapeInBackground')
	if [ "$ScrapeInBackground" = "true" ]; then

		if pgrep -f "/mnt/SDCARD/System/usr/trimui/scripts/scraper/scrap_screenscraper.sh" >/dev/null; then
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

		play_sound_after_scraping() {
			while kill -0 $1 2>/dev/null; do
				sleep 1
			done
			aplay "/mnt/SDCARD/trimui/res/sound/Background Scraping Finished.wav"
		}

		/mnt/SDCARD/System/usr/trimui/scripts/scraper/scrap_screenscraper.sh "$1" >$log_file 2>&1 &
		SCRAP_PID=$!

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

/mnt/SDCARD/System/bin/text_viewer -s "/mnt/SDCARD/System/usr/trimui/scripts/scraper/scrap_screenscraper.sh $1" -f 25 -t "                            ScreenScraper by Schmurtz.                     (Press B to stop)"

# Check if the scraping process is running
scraping_running() {
	pgrep -f "text_viewer" >/dev/null
}

while scraping_running; do

	if ! pgrep "getkey" >/dev/null; then
		touch /tmp/scrap_stop
		break
	fi

	sleep 2.5
done

# for pid in $(pgrep -f getkey.sh); do pkill -TERM -P $pid; done

# Remove the first line from the recentlist.json file
recentlist="/mnt/SDCARD/Roms/recentlist.json"
sed -i '1d' "$recentlist"
sync
