#!/bin/sh

if [ ! -f "/mnt/SDCARD/Emus/MSX2/openmsx/bin/openmsx" ]; then
  /mnt/SDCARD/System/bin/7zz x "/mnt/SDCARD/Emus/MSX2/openmsx_standalone.7z" -o"/mnt/SDCARD/Emus/MSX2/"
fi

openmsx_download_error() {
  /mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh \
    -i "/mnt/SDCARD/Emus/MSX2/openmsx/resources/background.png" \
    -c "0,0,0" \
    -f "/mnt/SDCARD/System/resources/DejaVuSans.ttf" \
    -m "Failed to download system rom. Connect to Wi-Fi and try again." \
    -fs 40 \
    -k " "
}

OM_DIR=/mnt/SDCARD/Emus/MSX2/openmsx
EMU_DIR=/mnt/SDCARD/Emus/MSX2

ROM_FILE=$(realpath "$1")

cd $OM_DIR

export OPENMSX_SYSTEM_DATA=$PWD/share
export HOME=$EMU_DIR

SERVER_URL="https://download.file-hunter.com/System%20ROMs/machines/panasonic"
AGENT="Mozilla/5.0 (X11; Linux x86_64; rv:60.0) Gecko/20100101 Firefox/81.0"

SYS_ROMS="fs-a1st_firmware.rom 
fs-a1st_kanjifont.rom"

for f in $SYS_ROMS; do
  if [ -f "./share/systemroms/$f" ]; then
    echo "Found sysrom $f"
  else
    echo "Downloading sysrom $f "
    curl --fail-early --connect-timeout 10 -k -A "$AGENT"@ "$SERVER_URL/$f" -o ./share/systemroms/$f
    if [ ! -f "./share/systemroms/$f" ]; then
      openmsx_download_error
      exit
    fi
  fi
done

exec bin/openmsx -machine Panasonic_FS-A1ST "$ROM_FILE" -ext scc+
