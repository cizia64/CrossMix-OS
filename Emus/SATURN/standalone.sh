#!/bin/sh
echo $0 $*
EMU_DIR=/mnt/SDCARD/Emus/SATURN

$EMU_DIR/performance.sh

cd $EMU_DIR/yabasanshiro
export HOME="$EMU_DIR/yabasanshiro"

if [ -f "/mnt/SDCARD/BIOS/saturn_bios.bin" ]; then
    echo "Using real Saturn BIOS"
    BIOS_FILE="/mnt/SDCARD/BIOS/saturn_bios.bin"
else
    echo "Using Yabasanshiro HLE BIOS"
fi

./gptokeyb "yabasanshiro" -c "keys.gptk" -k yabasanshiro &
./yabasanshiro -r 3 -i "$@" -b "$BIOS_FILE"
$ESUDO kill -9 $(pidof gptokeyb)