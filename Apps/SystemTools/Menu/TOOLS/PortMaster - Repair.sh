export PATH=/mnt/SDCARD/System/usr/trimui/scripts/:/mnt/SDCARD/System/bin:/usr/trimui/bin:$PATH
export LD_LIBRARY_PATH="/mnt/SDCARD/System/lib:/mnt/SDCARD/Apps/PortMaster/PortMaster:/usr/trimui/lib:$LD_LIBRARY_PATH"

button=$(infoscreen.sh -i bg-stop-exit.png -m "The repair process can be long (3 to 10 minutes). Run now ? A to continue B to cancel." -k "A B" -fs 29)
if [ "$button" = "B" ]; then
    exit
fi

/mnt/SDCARD/Apps/Terminal/launch.sh -e '/mnt/SDCARD/System/usr/trimui/scripts/portmaster_fix.sh'
