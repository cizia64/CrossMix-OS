#!/bin/sh

OM_DIR=/mnt/SDCARD/Emus/MSX2/openmsx
EMU_DIR=/mnt/SDCARD/Emus/MSX2

ROM_FILE=$(realpath "$1")

cd $OM_DIR

export OPENMSX_SYSTEM_DATA=$PWD/share
export HOME=$EMU_DIR

SERVER_URL="https://download.file-hunter.com/System%20ROMs/machines/panasonic"
AGENT="Mozilla/5.0 (X11; Linux x86_64; rv:60.0) Gecko/20100101 Firefox/81.0"

SYS_ROMS=" fs-a1wsx_basic-bios2p.rom
 fs-a1wsx_disk.rom
 fs-a1wsx_firmware.rom
 fs-a1wsx_fmbasic.rom
 fs-a1wsx_kanjibasic.rom
 fs-a1wsx_kanjifont.rom
 fs-a1wsx_msx2psub.rom"

for f in $SYS_ROMS
do
  if [ -f "./share/systemroms/$f" ]; then
    echo "Found sysrom $f"
  else
    echo "Downloading sysrom $f " 
    curl --fail-early --connect-timeout 10 -k -A "$AGENT" "$SERVER_URL/$f" -o ./share/systemroms/$f
    if [ ! -f "./share/systemroms/$f" ]; then
      ../openmsx_download_error.sh
      exit
    fi
  fi
done

exec bin/openmsx -machine Panasonic_FS-A1WSX "$ROM_FILE" -ext scc+
