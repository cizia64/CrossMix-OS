#!/bin/sh
echo $0 $*
PATH="/mnt/SDCARD/System/bin:$PATH"

CurrentSelection=$(basename "$1" | sed 's/\.[^.]*$//')

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
			/mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -i bg-stop-exit.png -m "A scraping task is already running in background." -t 3
			exit
		fi

		play_sound_after_scraping() {
			while kill -0 $1 2>/dev/null; do
				sleep 1
			done
			aplay "/mnt/SDCARD/trimui/res/sound/Background Scraping Finished.wav"
		}

		if [ "$CurrentSelection" = "° Scrape all" ]; then
			"/mnt/SDCARD/Apps/Scraper/Menu/° Scrape all.launch" >$log_file 2>&1 &
			SCRAP_PID=$!
		else
			/mnt/SDCARD/System/usr/trimui/scripts/scraper/scrap_screenscraper.sh "$1" >$log_file 2>&1 &
			SCRAP_PID=$!
		fi

		play_sound_after_scraping $SCRAP_PID &
		/mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -i bg-stop-exit.png -m "$CurrentSelection scraping launched in background." -t 3
		exit
	fi
fi
# ================================================================

"/mnt/SDCARD/System/usr/trimui/scripts/getkey.sh" B &

if [ "$CurrentSelection" = "° Scrape all" ]; then
	/mnt/SDCARD/System/bin/text_viewer -s "'/mnt/SDCARD/Apps/Scraper/Menu/° Scrape all.launch'" -f 25 -t "                            ScreenScraper by Schmurtz.                     (Press B to stop)"
else
	/mnt/SDCARD/System/bin/text_viewer -s "/mnt/SDCARD/System/usr/trimui/scripts/scraper/scrap_screenscraper.sh $1" -f 25 -t "                            ScreenScraper by Schmurtz.                     (Press B to stop)"
fi
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
