#!/usr/bin/env sh

export PATH="${PATH:+$PATH:}/mnt/SDCARD/System/bin"
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH:+$LD_LIBRARY_PATH:}/mnt/SDCARD/System/lib"

cd "$(dirname "$0")" 

pipe="/tmp/fifo"
mkfifo $pipe
(
    cat << 'EOF'
#!/usr/bin/env sh

term_menu_installed=$(pip3 list | grep -c "simple-term-menu")

if [ -z "$term_menu_installed" ]; then
    pip3 install simple-term-menu
    echo "simple-term-menu installed"
else
    echo "simple-term-menu already installed"
fi

python3 /mnt/SDCARD/Apps/ListCreator/collection_maker.py "/mnt/SDCARD/Roms/" "/mnt/SDCARD/Best/"

EOF
) > $pipe &
/mnt/SDCARD/Apps/Terminal/SimpleTerminal -e "sh $pipe"
rm -f $pipe
