#!/bin/sh
source /mnt/SDCARD/System/usr/trimui/scripts/common_launcher.sh
cpufreq.sh ondemand 2 7

RomFullPath=$1
progdir=$(dirname "$0")
romdir=$(dirname "$1")
romname=$(basename "$1")
romNameNoExtension=${romname%.*}

txt_file=$(sed -n '1p' "$RomFullPath" | tr -d '\r')
GameType=$(sed -n '2p' "$RomFullPath" | tr -d '\r')

# findind .txt framefile

if [ ! -f "$txt_file" ]; then
    echo " ---> $txt_file specified in $romname doesn't exist."
    txt_file="/mnt/SDCARD/Roms/DAPHNE/framefile/${romNameNoExtension}.txt"
    GameType="$romNameNoExtension"

    if [ ! -f "$txt_file" ]; then
        echo " ---> $txt_file doesn't exist."
        txt_file="/mnt/SDCARD/Roms/DAPHNE/framefile/${romNameNoExtension}.daphne/${romNameNoExtension}.txt"

        if [ ! -f "$txt_file" ]; then
            echo " ---> $txt_file doesn't exist."
            echo "."
            echo " ---> can't find ${romNameNoExtension}.txt"
            /mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "${romNameNoExtension}.txt not found." -t 1
            exit
        else
            echo " ---> $txt_file found."
        fi
    else
        echo " ---> $txt_file found."
    fi
else
    echo " ---> $txt_file found."
fi

txt_name=$(basename "$txt_file")
txt_nameNoExtension=${txt_name%.*}

# findind bezel
if [ -f "/mnt/SDCARD/Roms/DAPHNE/bezels/$txt_nameNoExtension.png" ]; then
    echo " ---> Bezel $txt_nameNoExtension.png found"
    bezel="$txt_nameNoExtension.png"
else
    echo " ---> Bezel $txt_nameNoExtension.png not found, using Daphne.png instead"
    bezel="Daphne.png"
fi

cd /mnt/SDCARD/Emus/DAPHNE/hypseus-singe/

./hypseus-singe $GameType vldp \
    -framefile "$txt_file" \
    -homedir "/mnt/SDCARD/Roms/DAPHNE/" \
    -datadir "/mnt/SDCARD/Roms/DAPHNE/" -fullscreen -bezel "$bezel" -useoverlaysb 2
