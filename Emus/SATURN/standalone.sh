#!/bin/sh
source /mnt/SDCARD/System/usr/trimui/scripts/common_launcher.sh
cpufreq.sh performance 7 7

# cwd is EMU_DIR
cd yabasanshiro

export HOME="$PWD"

if grep -i "dowork 0x" "/tmp/log/messages" | tail -n 1 | grep -iq "(HLE BIOS)"; then
    BIOS_FILE=""
    echo "Using Yabasanshiro HLE BIOS"
else
    BIOS_FILE="/mnt/SDCARD/BIOS/saturn_bios.bin"
    if [ ! -f "$BIOS_FILE" ]; then
        echo "BIOS file not found, falling back to HLE BIOS"
    else
        echo "Using real Saturn BIOS"
    fi
fi

./gptokeyb "yabasanshiro" -c "keys.gptk" -k yabasanshiro &
./yabasanshiro -r 3 -i "$@" -b "$BIOS_FILE"
$ESUDO kill -9 $(pidof gptokeyb)
