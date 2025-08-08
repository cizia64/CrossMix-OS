#!/bin/sh
if [ -n "$2" ]; then
    return
fi

ROM_PATH=$(realpath "$1")
rom_path_after_roms=${ROM_PATH#*/Roms/}
subdir_count=$(echo "$rom_path_after_roms" | grep -o '/' | wc -l)

if [ "$subdir_count" -gt 1 ]; then
    ROM_DIRECTORY=${ROM_PATH%/*}
    first_subdir=${rom_path_after_roms%%/*}
    ROM_FILENAME=$(basename "$1")
    ROM_FILENAME_NOEXT=${ROM_FILENAME%.*}
    SPOOFING_DIRECTORY="/tmp/folderspoof/$ROM_FILENAME_NOEXT/$first_subdir"

    echo "Subdirectory from $first_subdir detected !"

    mkdir -p "$SPOOFING_DIRECTORY"
    mount -o bind "$ROM_DIRECTORY" "$SPOOFING_DIRECTORY"

    POST_RUN_SCRIPT="/tmp/folderspoof/${ROM_FILENAME_NOEXT}_postrun.sh"
    cat <<EOF >"$POST_RUN_SCRIPT"
while kill -0 "$$" 2>/dev/null; do
  sleep 2
done
sync
umount "$SPOOFING_DIRECTORY"
if [ \$? = 0 ]; then
  sleep 1
  rmdir "$SPOOFING_DIRECTORY"
  rmdir "/tmp/folderspoof/$ROM_FILENAME_NOEXT"
fi
rm "${POST_RUN_SCRIPT}"
EOF

    chmod a+x "$POST_RUN_SCRIPT"
    "$POST_RUN_SCRIPT" &

    exec "$0" "$SPOOFING_DIRECTORY/$ROM_FILENAME" "alreadydone"
    exit
fi
