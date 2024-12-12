#!/bin/sh
export LD_LIBRARY_PATH="/mnt/SDCARD/System/lib:/usr/trimui/lib:/mnt/SDCARD/Apps/PortMaster/PortMaster:$LD_LIBRARY_PATH"

/mnt/SDCARD/Apps/PortMaster/PortMaster/gptokeyb2 -1 "Terminal" -c "/mnt/SDCARD/Apps/OTA-update/keys.gptk" &
/mnt/SDCARD/Apps/Terminal/launch.sh -e "/mnt/SDCARD/System/usr/trimui/scripts/ota_update.sh"

kill -9 $(pidof gptokeyb2)