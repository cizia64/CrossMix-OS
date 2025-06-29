#!/bin/sh
export PATH="/mnt/SDCARD/System/bin:/mnt/SDCARD/System/usr/trimui/scripts:$PATH"

CFG="./reader_choice.cfg"
ARCHIVE="./koreader.7z"
DEST_DIR="/mnt/SDCARD/Apps/koreader"
DEST_PARENT="/mnt/SDCARD/Apps"
button=""

# Vérifie si une config existe déjà
if [ -f "$CFG" ]; then
    button_state.sh L
    if [ $? -eq 10 ]; then
        rm -f "$CFG"
    else
        reader=$(cat "$CFG")
        case "$reader" in
            trimui) button="X" ;;
            pixel)  button="A" ;;
            ko)     button="B" ;;
        esac
    fi
fi

# Affiche l'écran de choix si aucune config ou bouton L pressé
if [ -z "$button" ]; then
    button=$(infoscreen.sh -i ./reader_choice.png -k "X A B MENU")
fi

# Sortie si MENU
[ "$button" = "MENU" ] && exit

# TrimUI Reader
if [ "$button" = "X" ]; then
    button_state.sh L
    [ $? -eq 10 ] && echo "trimui" >"$CFG"
    /usr/trimui/apps/bookreader/launch.sh
    exit
fi

# Pixel Reader
if [ "$button" = "A" ]; then
    button_state.sh L
    [ $? -eq 10 ] && echo "pixel" >"$CFG"

    export LD_LIBRARY_PATH="$(dirname "$0")/libs:/mnt/SDCARD/System/lib:$LD_LIBRARY_PATH"
    cd "$(dirname "$0")"

    /mnt/SDCARD/Apps/PortMaster/PortMaster/gptokeyb -k "reader" -c "./reader.gptk" &

    RESOLUTION=$(/mnt/SDCARD/Apps/PortMaster/PortMaster/sdl_resolution.aarch64 2>/dev/null | grep -a 'Current' | awk -F ': ' '{print $2}')
    export SCREEN_WIDTH=$(echo "$RESOLUTION" | cut -d'x' -f1)
    export SCREEN_HEIGHT=$(echo "$RESOLUTION" | cut -d'x' -f2)

    ./reader
    kill -9 $(pidof gptokeyb)
    exit
fi

# KOReader
if [ "$button" = "B" ]; then
    button_state.sh L
    [ $? -eq 10 ] && echo "ko" >"$CFG"

    if [ -f "$ARCHIVE" ] && [ ! -d "$DEST_DIR" ]; then
        echo "Extracting $ARCHIVE to $DEST_PARENT..."
        7zz x "$ARCHIVE" -o"$DEST_PARENT"
    fi

    cd "$DEST_DIR"
    ./launch.sh
    exit
fi
