#!/bin/sh
source /mnt/SDCARD/System/usr/trimui/scripts/common_launcher.sh
cpufreq.sh performance 7 7

# cwd is EMU_DIR

export HOME="$PWD"

choice=$(grep -i "dowork 0x" "/tmp/log/messages" | tail -n 1 | grep -i "(HLE BIOS)")
if [ -z "$choice" ]; then
    BIOS_FILE=""
    echo "Using Yabasanshiro HLE BIOS"
else
    BIOS_FILE="/mnt/SDCARD/BIOS/saturn_bios.bin"
    if [ ! -f "$BIOS_FILE" ]; then
        echo "BIOS file not found, falling back to HLE BIOS"
        /mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -i bg-exit.png -m "No bios found, Yabasanshiro will use HLE (less compatible)." -k "A B"
    else
        echo "Using real Saturn BIOS"
    fi
fi

if [ -f "/tmp/cmd_to_run.sh" ] && ! grep -q "dowork 0x" "/tmp/cmd_to_run.sh"; then
    sed -i "1s|^|echo \"$choice\" > /tmp/log/messages\n|" "/tmp/cmd_to_run.sh"
fi

./yabasanshiro -r 3 -i "$@" -b "$BIOS_FILE" &
activities add "$1" $!
