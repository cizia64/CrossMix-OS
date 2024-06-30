#!/bin/sh
echo $0 $*
source /mnt/SDCARD/System/usr/trimui/scripts/FolderOverrideFinder.sh
RA_DIR=/mnt/SDCARD/RetroArch
EMU_DIR=/mnt/SDCARD/Emus/PS
cd $RA_DIR/

if ! find "/mnt/SDCARD/BIOS" -maxdepth 1 -iname "scph*" -o -iname "psxonpsp660.bin" -o -iname "ps*.bin" | grep -q .; then
    /mnt/SDCARD/System/bin/sdl2imgshow \
      -i "/mnt/SDCARD/trimui/res/crossmix-os/bg-exit.png" \
      -f "/mnt/SDCARD/System/resources/DejaVuSans.ttf" \
      -s 40 \
      -c "220,220,220" \
      -t "No bios found, duckstation will probably not work." &

    /mnt/SDCARD/System/usr/trimui/scripts/getkey.sh

    pkill -f sdl2imgshow

fi

$EMU_DIR/performance.sh

#disable netplay
NET_PARAM=

HOME=$RA_DIR/ $RA_DIR/ra64.trimui -v $NET_PARAM -L $RA_DIR/.retroarch/cores/duckstation_libretro.so "$@"
