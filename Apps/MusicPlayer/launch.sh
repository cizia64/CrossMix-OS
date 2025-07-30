#!/bin/sh
export PATH="/mnt/SDCARD/System/bin:/mnt/SDCARD/System/usr/trimui/scripts:$PATH"

CFG="./player_choice.cfg"

# Checks if a default choice has already been saved
if [ -f "$CFG" ]; then
    button_state.sh L
    if [ $? -eq 10 ]; then
        rm -f "$CFG"
    else
        player=$(cat "$CFG")
        if [ "$player" = "gmu" ]; then
            ./gmu_launcher.sh
            exit
        elif [ "$player" = "trimui" ]; then
            /usr/trimui/apps/musicplayer/launch.sh
            exit
        fi
    fi
fi

# Displays choice screen if no config or if L was pressed
button=$(infoscreen.sh -i ./player_choice.png -k "A Y MENU")

if [ "$button" = "MENU" ]; then
    exit
fi

if [ "$button" = "Y" ]; then # Run TrimUI player
    button_state.sh L
    [ $? -eq 10 ] && echo "trimui" >"$CFG"
    /usr/trimui/apps/musicplayer/launch.sh
    exit
fi

if [ "$button" = "A" ]; then # Run GMU player
    button_state.sh L
    [ $? -eq 10 ] && echo "gmu" >"$CFG"

    # On désactive l'auto-play
    settings_file="/mnt/SDCARD/Apps/MusicPlayer/gmu.settings.conf"
    sed -i 's/^Gmu.AutoPlayOnProgramStart=yes$/Gmu.AutoPlayOnProgramStart=no/' "$settings_file"

    radios_archive="/mnt/SDCARD/Apps/MusicPlayer/Radios.7z"
    if [ -f "$radios_archive" ]; then
        infoscreen.sh -m "Extracting radio playlists, please wait..."
        7zz x -aoa "$radios_archive" -o"/mnt/SDCARD/Roms/MUSIC"
        mv "$radios_archive" "/mnt/SDCARD/Apps/MusicPlayer/Radios_extracted.7z"
    fi

    sync
    ./gmu_launcher.sh
    exit
fi
