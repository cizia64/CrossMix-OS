#!/bin/sh
echo $0 $*
progdir=$(dirname "$0")
mp3_directory=$(dirname "$1")

tkdir=/mnt/SDCARD/Apps/ScreencapTK
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/lib:/usr/trimui/lib/:$tkdir/lib
mp3_directory=$(realpath "$mp3_directory")

if [ "$mp3_directory" = "/mnt/SDCARD/Roms/MUSIC" ]; then
    echo "The given directory is the root directory. Please create a subfolder."
    /mnt/SDCARD/System/bin/sdl2imgshow \
        -i "/mnt/SDCARD/trimui/res/crossmix-os/bg-info.png" \
        -f "/mnt/SDCARD/System/resources/DejaVuSans.ttf" \
        -s 25 \
        -c "220,220,220" \
        -t "The given directory is the MUSIC root directory. Please create a dedicated subfolder." &
    sleep 0.3
    pkill -f sdl2imgshow
    sleep 1
    sleep 2
    exit 0
fi

/mnt/SDCARD/System/bin/sdl2imgshow \
    -i "/mnt/SDCARD/trimui/res/crossmix-os/bg-info.png" \
    -f "/mnt/SDCARD/System/resources/DejaVuSans.ttf" \
    -s 25 \
    -c "220,220,220" \
    -t "Cover extraction. Please wait..." &
sleep 0.3
pkill -f sdl2imgshow

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
