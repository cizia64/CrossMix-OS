#!/bin/sh
source /mnt/SDCARD/System/usr/trimui/common_launcher.sh

echo $0 $*
EMU_DIR=/mnt/SDCARD/Emus/SATURN

cpufreq.sh performance 7 7

cd $EMU_DIR/yabasanshiro
export HOME="$EMU_DIR/yabasanshiro"

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
