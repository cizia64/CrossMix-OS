#!/bin/sh
source /mnt/SDCARD/System/usr/trimui/scripts/common_launcher.sh
export picodir=/mnt/SDCARD/Emus/PICO/PICO8_Wrapper
cpufreq.sh ondemand 0 6
cd $picodir
export PATH=$PATH:$PWD/bin
export HOME=$picodir
export PATH=${picodir}:$PATH
export LD_LIBRARY_PATH="$picodir/lib:/usr/lib:$LD_LIBRARY_PATH"

if ! [ -f /mnt/SDCARD/Emus/PICO/PICO8_Wrapper/bin/pico8_64 ] || ! [ -f /mnt/SDCARD/Emus/PICO/PICO8_Wrapper/bin/pico8.dat ]; then
	LD_LIBRARY_PATH="/mnt/SDCARD/System/lib:/usr/trimui/lib:$LD_LIBRARY_PATH"
	/mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "To use the official PICO-8, you need to add your purchased binaries (pico8_64 and pico8.dat)." -fs 25 -t 5
fi

main() {
	#echo 1008000 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq
	echo performance >/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
	mount --bind /mnt/SDCARD/Roms/PICO8 /mnt/SDCARD/Emus/PICO/PICO8_Wrapper/.lexaloffle/pico-8/carts
	pico8_64 -preblit_scale 3 -run "$1"
	umount /mnt/SDCARD/Apps/pico/.lexaloffle/pico-8/carts
	echo ondemand >/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
}

main "$1"
