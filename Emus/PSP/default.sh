#!/bin/ash

rom_file=$(basename "$1")
ext=${rom_file##*.}

cfg_folder=/mnt/SDCARD/Roms/PSP/.games_config/
cfg_file=${1%.*}.cfg

# If there is a loader saved by user or the filename already match crossmix presets, skip
if [ ! -f "$cfg_folder/$cfg_file" ]; then
    if [ "$ext" == "chd" ]; then
        hash=$(/mnt/System/bin/chdman info -i "$1" | sed -nE 's/^Data SHA1:[[:space:]]+(.*)$/\1/p')
        real_name=$(grep "/mnt/SDCARD/Emus/PSP/redump_names.dat" "$hash" | cut -d "=" -f 2)
    elif [ "$ext" == "iso" ]; then
        hash=$(sha1sum "$1" | cut -d ' ' -f 1)
        real_name=$(grep "/mnt/SDCARD/Emus/PSP/redump_names.dat" "$hash" | cut -d "=" -f 2)
    fi
    if [ -n "$real_name" ] && [ -f "$cfg_folder/${real_name%.*}.cfg" ]; then
        cp "$cfg_folder/${real_name%.*}.cfg" "$cfg_folder/$cfg_file"
    else
        /mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "No CrossMix launcher preset for this game. You should save yourself a launcher for this game to reduce next startup duration." -k "A B"
    fi
fi

source /mnt/SDCARD/System/usr/trimui/scripts/load_launcher.sh
