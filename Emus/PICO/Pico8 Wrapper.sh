#!/bin/sh
source /mnt/SDCARD/System/usr/trimui/scripts/launchers/common_launcher.sh
cpufreq.sh ondemand 5 7

cd PICO8_Wrapper/

export picodir="$PWD"

export PATH="${PATH:+$PATH:}$PWD/bin"
export HOME="$PWD"
export PATH="${PWD}:$PATH"
export LD_LIBRARY_PATH="$PWD/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

if ! [ -f bin/pico8_64 ] || ! [ -f bin/pico8.dat ]; then
	/mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "To use the official PICO-8, you need to add your purchased binaries (pico8_64 and pico8.dat)." -fs 25 -t 5
    exit
fi

mount --bind /mnt/SDCARD/Roms/PICO8 "$PWD/.lexaloffle/pico-8/carts"

pico8_64 -preblit_scale 3 -run "$1"

umount /mnt/SDCARD/Apps/pico/.lexaloffle/pico-8/carts
