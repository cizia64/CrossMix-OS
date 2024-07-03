#!/bin/sh

# Check the number of arguments
if [ $# -ne 1 ]; then
  echo "Usage: $0 <directory>"
  exit 1
fi

# Given directory
mp3_directory=$(dirname "$1")

# Check if the directory is the root directory
mp3_directory=$(realpath "$mp3_directory")
root_directory=$(realpath "/mnt/SDCARD/Roms/MUSIC")

if [ "$mp3_directory" = "$root_directory" ]; then
  echo "The given directory is the root directory. No playlist will be created."
  /mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "The given directory is the MUSIC root directory. No playlist will be created." -fs 25 -t 3
  exit 0
fi

# Name of the .m3u file in the parent directory
MUSIC_DIR=$(basename "$(dirname "$1")")
PARENT_DIR=$(dirname "$mp3_directory")
TARGET_PLAYLIST_FILE="$PARENT_DIR/$(basename "$mp3_directory").m3u"
PLAYLIST_FILE="$mp3_directory/$(basename "$mp3_directory").m3u"

/mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "Building playlist for $MUSIC_DIR folder." -fs 25

# Create the .m3u file
echo "#EXTM3U" >"$PLAYLIST_FILE"

# Iterate through .mp3 files in the given directory and add them to the .m3u file
find "$mp3_directory" -type f -name "*.mp3" | while read -r MP3_FILE; do

  # Extract the name of the MP3 file (e.g., test.mp3)
  MP3_NAME=$(basename "$MP3_FILE")

  echo "$MUSIC_DIR/$MP3_NAME" >>"$PLAYLIST_FILE"
done
sync
sleep 1
sync
/mnt/SDCARD/Emus/MUSIC/cover_extract.sh "$1"
sync
mv "$PLAYLIST_FILE" "$TARGET_PLAYLIST_FILE"
rm /mnt/SDCARD/Roms/MUSIC/MUSIC_cache7.db
sync
echo "The file $(basename "$mp3_directory").m3u has been created in $PARENT_DIR."
