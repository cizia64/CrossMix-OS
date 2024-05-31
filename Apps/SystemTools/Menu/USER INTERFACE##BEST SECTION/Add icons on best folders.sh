#!/bin/sh
echo $0 $*

/mnt/SDCARD/System/bin/sdl2imgshow \
    -i "/mnt/SDCARD/trimui/res/crossmix-os/bg-info.png" \
    -f "/mnt/SDCARD/System/resources/DejaVuSans.ttf" \
    -s 40 \
    -c "220,220,220" \
    -t "$(basename "$0" .sh)." &

PATH="/mnt/SDCARD/System/bin:$PATH"
export LD_LIBRARY_PATH="/mnt/SDCARD/System/lib:/usr/trimui/lib:$LD_LIBRARY_PATH"

# Define the path to the directory containing the databases
database_dir="/mnt/SDCARD/Best/"

# Iterate through each directory
for db_dir in "$database_dir"/*; do
    # Check if the path is a directory
    if [ -d "$db_dir" ]; then
        ppathChange=0
        # Extract the directory name
        subdir_name=$(basename "$db_dir")
        # Construct the path to the database
        database_file="$db_dir/Roms/Roms_cache7.db"

        # Check if the database exists
        if [ -f "$database_file" ]; then
            echo "Processing database: $database_file"

            # Iterate through the database and update image paths
            sqlite3 "$database_file" "SELECT path, disp FROM Roms_roms WHERE type = 1;" |
                while IFS='|' read -r path disp; do
                    # Construct the image path
                    imgpath="/mnt/SDCARD/Icons/Default/Logos/$(basename "$path").png"

                    # Update the display field based on the original value
                    case "$disp" in
                    ATARI2600) new_value="Atari - 2600" ;;
                    FIFTYTWOHUNDRED) new_value="Atari - 5200" ;;
                    SEVENTYEIGHTHUNDRED) new_value="Atari - 7800" ;;
                    LYNX) new_value="Atari - Lynx" ;;
                    DOS) new_value="DOS" ;;
                    FBNEO) new_value="FBNeo - Arcade Games" ;;
                    PCE) new_value="NEC - PC Engine - TurboGrafx 16" ;;
                    PCECD) new_value="NEC - PC Engine CD - TurboGrafx-CD" ;;
                    GB) new_value="Nintendo - Game Boy" ;;
                    GBA) new_value="Nintendo - Game Boy Advance" ;;
                    GBC) new_value="Nintendo - Game Boy Color" ;;
                    N64) new_value="Nintendo - Nintendo 64" ;;
                    NDS) new_value="Nintendo - Nintendo DS" ;;
                    FC) new_value="Nintendo - NES" ;;
                    POKE) new_value="Nintendo - Pokemon Mini" ;;
                    SFC) new_value="Nintendo - SNES" ;;
                    NEOGEO) new_value="SNK - Neo Geo" ;;
                    NEOCD) new_value="SNK - Neo Geo CD" ;;
                    NGP) new_value="SNK - Neo Geo Pocket" ;;
                    NGP) new_value="SNK - Neo Geo Pocket Color" ;;
                    SCUMMVM) new_value="ScummVM" ;;
                    SEGA32X) new_value="Sega - 32X" ;;
                    DC) new_value="Sega - Dreamcast" ;;
                    GG) new_value="Sega - Game Gear" ;;
                    MS) new_value="Sega - Master System - Mark III" ;;
                    MD) new_value="Sega - Mega Drive - Genesis" ;;
                    SEGACD) new_value="Sega - Mega-CD - Sega CD" ;;
                    SATURN) new_value="Sega - Saturn" ;;
                    PS) new_value="Sony - PlayStation" ;;
                    PSP) new_value="Sony - PlayStation Portable" ;;
                    PANASONIC) new_value="The 3DO Company - 3DO" ;;
                    CPC) new_value="Amstrad - CPC" ;;
                    ATARIST) new_value="Atari - ST" ;;
                    COLECO) new_value="Coleco - ColecoVision" ;;
                    INTELLIVISION) new_value="Mattel - Intellivision" ;;
                    LUTRO) new_value="Lutro" ;;
                    MSX) new_value="Microsoft - MSX" ;;
                    TIC) new_value="TIC-80" ;;
                    VECTREX) new_value="GCE - Vectrex" ;;
                    ZXS) new_value="Sinclair - ZX Spectrum" ;;
                    *) new_value="$disp" ;; # Default to the original value if no match found
                    esac

                    echo "New folder imgpath: $imgpath"
                    echo "path = $path"
                    echo "Old disp = $disp, New disp = $new_value"

                    # Update the database with the new image path and display value
                    sqlite3 "$database_file" "UPDATE Roms_roms SET imgpath = '$imgpath', disp = '$new_value' WHERE path = '$path';"
                    sync
                    echo "==== UPDATE Roms_roms SET imgpath = '$imgpath', disp = '$new_value' WHERE path = '$path';"
                done

            # We have changed the folders names, so we change the ppath on each roms too
            sqlite3 "$database_file" "SELECT DISTINCT ppath FROM Roms_roms WHERE type = 0;" |
                while IFS='|' read -r ppath; do
                    # Determine the new value for ppath based on the original value
                    case "$ppath" in
                    ATARI2600) new_value="Atari - 2600" ;;
                    FIFTYTWOHUNDRED) new_value="Atari - 5200" ;;
                    SEVENTYEIGHTHUNDRED) new_value="Atari - 7800" ;;
                    LYNX) new_value="Atari - Lynx" ;;
                    DOS) new_value="DOS" ;;
                    FBNEO) new_value="FBNeo - Arcade Games" ;;
                    PCE) new_value="NEC - PC Engine - TurboGrafx 16" ;;
                    PCECD) new_value="NEC - PC Engine CD - TurboGrafx-CD" ;;
                    GB) new_value="Nintendo - Game Boy" ;;
                    GBA) new_value="Nintendo - Game Boy Advance" ;;
                    GBC) new_value="Nintendo - Game Boy Color" ;;
                    N64) new_value="Nintendo - Nintendo 64" ;;
                    NDS) new_value="Nintendo - Nintendo DS" ;;
                    FC) new_value="Nintendo - NES" ;;
                    POKE) new_value="Nintendo - Pokemon Mini" ;;
                    SFC) new_value="Nintendo - SNES" ;;
                    NEOGEO) new_value="SNK - Neo Geo" ;;
                    NEOCD) new_value="SNK - Neo Geo CD" ;;
                    NGP) new_value="SNK - Neo Geo Pocket" ;;
                    NGP) new_value="SNK - Neo Geo Pocket Color" ;;
                    SCUMMVM) new_value="ScummVM" ;;
                    SEGA32X) new_value="Sega - 32X" ;;
                    DC) new_value="Sega - Dreamcast" ;;
                    GG) new_value="Sega - Game Gear" ;;
                    MS) new_value="Sega - Master System - Mark III" ;;
                    MD) new_value="Sega - Mega Drive - Genesis" ;;
                    SEGACD) new_value="Sega - Mega-CD - Sega CD" ;;
                    SATURN) new_value="Sega - Saturn" ;;
                    PS) new_value="Sony - PlayStation" ;;
                    PSP) new_value="Sony - PlayStation Portable" ;;
                    PANASONIC) new_value="The 3DO Company - 3DO" ;;
                    CPC) new_value="Amstrad - CPC" ;;
                    ATARIST) new_value="Atari - ST" ;;
                    COLECO) new_value="Coleco - ColecoVision" ;;
                    INTELLIVISION) new_value="Mattel - Intellivision" ;;
                    LUTRO) new_value="Lutro" ;;
                    MSX) new_value="Microsoft - MSX" ;;
                    TIC) new_value="TIC-80" ;;
                    VECTREX) new_value="GCE - Vectrex" ;;
                    ZXS) new_value="Sinclair - ZX Spectrum" ;;
                    *) new_value="$ppath" ;; # Default to the original value if no match found
                    esac

                    echo "Old ppath = $ppath, New ppath = $new_value"

                    # Update the database with the new ppath value
                    sqlite3 "$database_file" "UPDATE Roms_roms SET ppath = '$new_value' WHERE ppath = '$ppath';"
                    sync
                    echo "==== UPDATE Roms_roms SET ppath = '$new_value' WHERE ppath = '$ppath';"
                done

        else
            echo "Database not found: $database_file"
        fi
    fi
done
sleep 0.1
pkill -f sdl2imgshow
sync
