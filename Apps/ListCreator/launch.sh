#!/usr/bin/env sh

export PATH="${PATH:+$PATH:}/mnt/SDCARD/System/bin"
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH:+$LD_LIBRARY_PATH:}/mnt/SDCARD/System/lib"

cd "$(dirname "$0")"

script="/tmp/coll_maker.sh"
cat >$script <<'EOF'
term_menu_installed=$(pip3 list | grep -c "simple-term-menu")

if [ -z "$term_menu_installed" ]; then
    pip3 install simple-term-menu
fi

python3 /mnt/SDCARD/Apps/ListCreator/collection_maker.py "/mnt/SDCARD/Roms/" "/mnt/SDCARD/Imgs" "/mnt/SDCARD/Best/" 
exit 0

EOF
/mnt/SDCARD/Apps/Terminal/SimpleTerminal -e sh $script
rm -f $script
