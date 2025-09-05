#!/bin/sh
source "/mnt/SDCARD/System/usr/trimui/scripts/romscripts/scraping/Remove current cover.sh"
"/mnt/SDCARD/System/usr/trimui/scripts/scraper/scrap_screenscraper.sh" "$(basename "$EMU_DIR")" "$(basename "$ROM_REAL_PATH")" &
