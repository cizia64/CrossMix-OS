# Sourced in common_launcher.sh
# Goal is to move rom to root of system folder as retroarch correctly detect the content directory
# If rom used is a m3u, all sub roms will also be moved.
# If rom used is a .cue, bin file will also be moved.
# preload.sh will move back files to their original location once rom is closed or at next startup.


move_and_save() {
    # Move the rom to System folder as retroarch content folder override is recognized
    mv "$1" "$2"

    # Save original and temp pos to restore them latter in preload.sh
    echo "$1" >>/mnt/SDCARD/to_move_dst
    echo "$2" >>/mnt/SDCARD/to_move_src

    # Do it for .bin too if the rom is a cue file.
    if [ "${1##*.}" = "cue" ]; then
        bin_file_src="${1%.*}.bin"
        bin_file_dst="${2%.*}.bin"
        mv "$bin_file_src" "$bin_file_dst" >/dev/null

        echo "$bin_file_src" >>/mnt/SDCARD/to_move_dst
        echo "$bin_file_dst" >>/mnt/SDCARD/to_move_src
    fi
}

# Subdirs example : MAME/0/1943.zip
subdirs=${1##*/Roms/}
# System=MAME
System=${subdirs%%/*}
ROM_DIR="/mnt/SDCARD/Roms/$System"

# If rom is a m3u, move all discs first and use the to_move_src file as new m3u.
if [ "${1##*.}" = "m3u" ]; then
    # Goto the m3u location
    cd "${1%%/*}"
    while read rom; do
        new_rom="$ROM_DIR/${rom##*/}"
        [ "$rom" != "$new_rom" ] && move_and_save "$rom" "$new_rom"
    done <"$1"
    cd -

    # Use the list of moved files as new m3u (if bin/cue moved, remove .bin ones)
    new_m3u="$ROM_DIR/${1##*/}"
    sed '/.*\.bin/d' /mnt/SDCARD/to_move_src > "$new_m3u"
    # Mark the new m3u as to be deleted by preload.sh
    echo "$new_m3u" >/mnt/SDCARD/to_del
    # Update $1
    set -- "$new_m3u"
else
    new_rom="$ROM_DIR/${1##*/}"
    if [ "$1" != "$new_rom" ]; then
        move_and_save "$1" "$new_rom"
        set -- "$new_rom"
    fi
fi
