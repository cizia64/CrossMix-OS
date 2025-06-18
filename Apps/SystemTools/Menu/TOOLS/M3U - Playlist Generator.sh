#!/bin/sh

export LD_LIBRARY_PATH=/mnt/SDCARD/Apps/TubeExJuk:/mnt/SDCARD/System/lib:/lib64:/usr/trimui/lib:/usr/lib
export PATH=$PATH:/mnt/SDCARD/System/bin

DIR_LIST="PS SEGACD NEOCD PCE PCFX AMIGA"
TOTAL=0
Message=""

for dir in $DIR_LIST; do
    /mnt/SDCARD/System/bin/presenter \
        --message "$Message\n$dir playlist(s) creation..." \
        --font-default "/mnt/SDCARD/Themes/CrossMix - OS/wqy-microhei.ttf" \
        --background-image "/mnt/SDCARD/trimui/res/crossmix-os/bg-info.png" \
        --message-alignment top \
        --horizontal-alignment left \
        --preserve-framebuffer \
        --line-spacing 0 \
        --show-spinner &

    COUNT=$(python3.11 "/mnt/SDCARD/System/usr/trimui/scripts/M3U - Playlist Generator.py" -md "/mnt/SDCARD/Roms/$dir" | grep '^TOTAL_M3U_CREATED=' | cut -d= -f2)
    sleep 2
    pkill -9 presenter
    sleep 0.5

    # Si COUNT est vide, on met 0
    COUNT=${COUNT:-0}
    TOTAL=$((TOTAL + COUNT))
    Message="$Message\n$dir playlist(s) created: $COUNT"

done

Message="$Message\n \n--------------------------------------\nFinished.\n \nTotal playlist(s) created: $TOTAL\n \n--------------------------------------\n \n \n                            Press B to quit"

# Message final
/mnt/SDCARD/System/bin/presenter \
    --message "$Message" \
    --font-default "/mnt/SDCARD/Themes/CrossMix - OS/wqy-microhei.ttf" \
    --background-image "/mnt/SDCARD/trimui/res/crossmix-os/bg-info.png" \
    --message-alignment top \
    --horizontal-alignment left \
    --preserve-framebuffer \
    --line-spacing 0 --action-show

exit 0
