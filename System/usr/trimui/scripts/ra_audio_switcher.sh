#!/bin/sh

if [ -f "/tmp/btdev_addr" ]; then
    echo "Bluetooth in use: Retroarch audio driver set to alsa"
    /mnt/SDCARD/System/usr/trimui/scripts/set_ra_cfg.sh "/mnt/SDCARD/RetroArch/retroarch.cfg" "audio_driver" "alsa"
else
    echo "Bluetooth not in use: Retroarch audio driver set to oss"
    
    if ! grep -q 'audio_driver *= *"oss"' /mnt/SDCARD/RetroArch/retroarch.cfg; then
        /mnt/SDCARD/System/usr/trimui/scripts/set_ra_cfg.sh "/mnt/SDCARD/RetroArch/retroarch.cfg" "audio_driver" "oss"
    fi
fi


if pgrep "mplayer" >/dev/null; then
    CHOICE=$(/mnt/SDCARD/System/bin/presenter --file /mnt/SDCARD/System/resources/Background_Music_choice.json --confirm-button A --no-wrap)
    
    if [ "$CHOICE" = "1" ]; then
        /mnt/SDCARD/System/usr/trimui/scripts/set_ra_cfg.sh "/mnt/SDCARD/RetroArch/retroarch.cfg" "audio_driver" "alsa"
        elif [ "$CHOICE" = "2" ]; then
        pkill -9 musicserver
        pkill -9 mplayer
        if ! grep -q 'audio_driver *= *"oss"' /mnt/SDCARD/RetroArch/retroarch.cfg; then
            /mnt/SDCARD/System/usr/trimui/scripts/set_ra_cfg.sh "/mnt/SDCARD/RetroArch/retroarch.cfg" "audio_driver" "oss"
        fi
    fi
fi
