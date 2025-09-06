#!/bin/sh
export LD_LIBRARY_PATH=/mnt/SDCARD/System/lib:/lib64:/usr/trimui/lib:/usr/lib
export PATH=$PATH:/mnt/SDCARD/System/bin

DIR_LIST="PS SEGACD NEOCD PCE PCFX AMIGA"
TOTAL=0
Message=""

for dir in $DIR_LIST; do
    /mnt/SDCARD/System/usr/trimui/scripts/infoscreen2.sh -m "$Message\n$dir playlist(s) creation..." -fi 0 -p top-left -fb -sp &

    COUNT=$(python3.11 "/mnt/SDCARD/System/usr/trimui/scripts/M3U - Playlist Generator.py" -md "/mnt/SDCARD/Roms/$dir" | grep '^TOTAL_M3U_CREATED=' | cut -d= -f2)

    COUNT=${COUNT:-0}
    TOTAL=$((TOTAL + COUNT))
    Message="$Message\n$dir playlist(s) created: $COUNT"
    sleep 1.5
done

Message="$Message\n"
Message="$Message\n \n--------------------------------------\n"
Message="$Message Finished.\n"
Message="$Message \nTotal playlist(s) created: $TOTAL\n"
Message="$Message \n--------------------------------------"

if [ "$TOTAL" -gt 0 ]; then
    for dir in $DIR_LIST; do
        rm -f "/mnt/SDCARD/Roms/$dir/${dir}_cache7.db"
    done
fi

/mnt/SDCARD/System/usr/trimui/scripts/infoscreen2.sh -m "$Message" -fi 0 -p top-left -k rin B "Exit"
