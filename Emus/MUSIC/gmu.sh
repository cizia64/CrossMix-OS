#!/bin/sh
PATH="/mnt/SDCARD/System/bin:$PATH"
echo $0 $*
echo "-------------------------------------------------"
folder=$(dirname "$(realpath "$1")")
progdir=$(dirname "$0")
homedir=$(dirname "$1")
settings_file="/mnt/SDCARD/Apps/MusicPlayer/gmu.settings.conf"
music_configfile="/mnt/SDCARD/Emus/MUSIC/config.json"
playlist="/mnt/SDCARD/Apps/MusicPlayer/.local/share/gmu/playlist.m3u"

extlist=$(jq -r '.extlist' "$music_configfile")

sed -i 's/^Gmu.AutoPlayOnProgramStart=no$/Gmu.AutoPlayOnProgramStart=yes/' "$settings_file"

Launcher=$(grep -i "dowork 0x" "/tmp/log/messages" | tail -n 1)

mkdir -p /mnt/SDCARD/Apps/MusicPlayer/.local/share/gmu/

# we add all the supported files from the current folder
if echo "$Launcher" | grep -q "folder"; then
    rm "$playlist"
    valid_extensions=$(echo "$extlist" | tr '|' '\n')
    for file in "$folder"/*; do
        if [ -f "$file" ]; then
            extension="${file##*.}"
            extension=$(echo "$extension" | tr '[:upper:]' '[:lower:]')
            for ext in $valid_extensions; do
                if [ "$extension" = "$ext" ]; then
                    echo "$file" >>"$playlist" # Ajouter le fichier à la playlist
                    break
                fi
            done
        fi
    done

else

    filepath=$(realpath "$1")
    if echo "$filepath" | grep -i '\.m3u$' >/dev/null; then
        cat "$filepath" >"$playlist"
    else
        echo "$filepath" >"$playlist"
    fi
fi

sync
/mnt/SDCARD/Apps/MusicPlayer/gmu_launcher.sh
