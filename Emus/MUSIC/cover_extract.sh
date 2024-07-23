#!/bin/sh
source /mnt/SDCARD/System/usr/trimui/scripts/launchers/common_launcher.sh
cpufreq.sh conservative 0 6

mp3_directory=$(dirname "$1")

export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/mnt/SDCARD/Apps/ScreencapTK/lib
mp3_directory=$(realpath "$mp3_directory")

if [ "$mp3_directory" = "/mnt/SDCARD/Roms/MUSIC" ]; then
    echo "The given directory is the root directory. Please create a subfolder."
    infoscreen.sh -m "The given directory is the MUSIC root directory. Please create a dedicated subfolder." -fs 25 -t 3
    exit 0
fi

infoscreen.sh -m "Cover extraction. Please wait..." -fs 25

# Directories
# mp3_directory="/mnt/SDCARD/Roms/MUSIC" #debug
png_directory="/mnt/SDCARD/Imgs/MUSIC"

# Create the images directory if it doesn't exist
mkdir -p "$png_directory"

# Find the first MP3 file
first_mp3=""
for file in "$mp3_directory"/*.mp3; do
    if [ -f "$file" ]; then
        first_mp3="$file"
        break
    fi
done

if [ -z "$first_mp3" ]; then
    echo "No MP3 files found in the directory."
    exit 1
fi

# Check for the existence of cover.jpg or cover.png
cover_image="$mp3_directory/cover.png"
cover_jpg="$mp3_directory/cover.jpg"
cover_png_already_existed=false

if [ -f "$cover_image" ]; then
    echo "cover.png already exists, using it."
    cover_png_already_existed=true
elif [ -f "$cover_jpg" ]; then
    echo "cover.jpg already exists, converting to cover.png."
    /mnt/SDCARD/Apps/ScreencapTK/bin/ffmpeg -i "$cover_jpg" -vf "scale=400:-1" "$cover_image"
else
    echo "Extracting cover from the first MP3."
    /mnt/SDCARD/Apps/ScreencapTK/bin/ffmpeg -i "$first_mp3" -an -vcodec copy "$cover_image"
fi

# Create a copy of the extracted image for each MP3 file in the images directory
for file in "$mp3_directory"/*.mp3; do
    if [ -f "$file" ]; then
        mp3_base_name=$(basename "$file" .mp3)
        new_cover_image="$png_directory/$mp3_base_name.png"
        cp "$cover_image" "$new_cover_image"
    fi
done

# Create a copy of the extracted image for each M3U file in the images directory
for file in "$mp3_directory"/*.m3u; do
    if [ -f "$file" ]; then
        m3u_base_name=$(basename "$file" .m3u)
        new_cover_image="$png_directory/$m3u_base_name.png"
        cp "$cover_image" "$new_cover_image"
    fi
done

# Remove the cover.png used for copying if it didn't already exist
if [ "$cover_png_already_existed" = false ]; then
    rm "$cover_image"
fi

sync
echo "Covers have been created for each MP3 and M3U file in the images directory."
