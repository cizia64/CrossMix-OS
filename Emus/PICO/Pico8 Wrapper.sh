#!/bin/sh
cd "$(dirname "$0")"

source /mnt/SDCARD/System/usr/trimui/scripts/common_launcher.sh

cd "$PWD/PICO8_Wrapper"

export picodir="$PWD"

export PATH="${PATH:+$PATH:}$PWD/bin"
export HOME="$PWD"
export PATH="${PWD}:$PATH"
export LD_LIBRARY_PATH="$PWD/lib:/usr/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

if ! [ -f bin/pico8_64 ] || ! [ -f bin/pico8.dat ]; then
	LD_LIBRARY_PATH="/mnt/SDCARD/System/lib:/usr/trimui/lib:$LD_LIBRARY_PATH"
	/mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "To use the official PICO-8, you need to add your purchased binaries (pico8_64 and pico8.dat)." -fs 25 -t 5
    exit
fi

#echo 1008000 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq
echo performance >/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
mount --bind /mnt/SDCARD/Roms/PICO8 "$PWD/.lexaloffle/pico-8/carts"

pico8_64 -preblit_scale 3 -run "$1"

umount /mnt/SDCARD/Apps/pico/.lexaloffle/pico-8/carts
echo ondemand >/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
