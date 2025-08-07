#!/bin/sh
if [ -n "$2" ]; then
    return
fi

ROM_PATH=$(realpath "$1")
rom_path_after_roms=${ROM_PATH#*/Roms/}
subdir_count=$(echo "$rom_path_after_roms" | grep -o '/' | wc -l)

if [ "$subdir_count" -gt 1 ]; then
    ROM_DIRECTORY=$(dirname "$ROM_PATH")
    ROM_FILENAME=$(basename "$1")
    ROM_FILENAME_NOEXT=${ROM_FILENAME%.*}
    first_subdir=$(echo "$rom_path_after_roms" | cut -d'/' -f1)
    SPOOFING_DIRECTORY="/tmp/folderspoof/$ROM_FILENAME_NOEXT/$first_subdir"
    echo $SPOOFING_DIRECTORY >"/tmp/${ROM_FILENAME}_spoofing_directory.txt"
    echo "Subdirectory from $first_subdir detected !"
    mkdir -p "$SPOOFING_DIRECTORY"
    mount -o bind "$ROM_DIRECTORY" "$SPOOFING_DIRECTORY" >/tmp/txtfolderspoof

    POST_RUN_SCRIPT="/tmp/folderspoof/${ROM_FILENAME_NOEXT}_postrun.sh"
    {
        echo "while kill -0 "$$" 2>/dev/null; do"
        echo "sleep 2"
        echo "done"
        echo "sync"
        echo "umount \"$SPOOFING_DIRECTORY\""
        echo "if [ \$? = 0 ]; then"
        echo "rm -rf \"$SPOOFING_DIRECTORY\""
        echo "fi"
    } >"$POST_RUN_SCRIPT"

    chmod a+x "$POST_RUN_SCRIPT"
    "$POST_RUN_SCRIPT" &

    exec "$0" "$SPOOFING_DIRECTORY/$ROM_FILENAME" "alreadydone"
    exit
fi
