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
	/mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "To use PICO-8 Wrapper, you need purchased PICO-8 binaries (add pico8_64 and pico8.dat)." -fs 25 -t 5
	exit
else
	if [ -f "/mnt/SDCARD/Roms/PICO/° Run Splore.launch" ]; then
		mv "/mnt/SDCARD/Roms/PICO/° Run Splore.launch" "/mnt/SDCARD/Roms/PICO/° Run Splore.p8"
		rm "/mnt/SDCARD/Roms/PICO/PICO_cache7.db"
		/mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -i bg-exit.png -m "To exit PICO-8 Wrapper, press Menu + Power buttons during 3 seconds." -k "B A"
	fi
fi

#echo 1008000 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq
echo performance >/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
mount --bind /mnt/SDCARD/Roms/PICO8 "$PWD/.lexaloffle/pico-8/carts"

pico8_64 -splore -preblit_scale 3

umount /mnt/SDCARD/Apps/pico/.lexaloffle/pico-8/carts
echo ondemand >/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
