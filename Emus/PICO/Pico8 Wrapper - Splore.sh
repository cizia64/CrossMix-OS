#!/bin/sh
export picodir=/mnt/SDCARD/Emus/PICO/PICO8_Wrapper
cd $picodir
export PATH=$PATH:$PWD/bin
export HOME=$picodir
export PATH=${picodir}:$PATH
export LD_LIBRARY_PATH="$picodir/lib:/usr/lib:$LD_LIBRARY_PATH"

if ! [ -f /mnt/SDCARD/Emus/PICO/PICO8_Wrapper/bin/pico8_64 ] || ! [ -f /mnt/SDCARD/Emus/PICO/PICO8_Wrapper/bin/pico8.dat ]; then
	LD_LIBRARY_PATH="/mnt/SDCARD/System/lib:/usr/trimui/lib:$LD_LIBRARY_PATH"

	/mnt/SDCARD/System/bin/sdl2imgshow \
		-i "/mnt/SDCARD/trimui/res/crossmix-os/bg-info.png" \
		-f "/mnt/SDCARD/System/resources/DejaVuSans.ttf" \
		-s 25 \
		-c "220,220,220" \
		-t "To use the official PICO-8, you need to add your purchased binaries (pico8_64 and pico8.dat)." &
	sleep 5
	pkill -f sdl2imgshow

fi

main() {
	#echo 1008000 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq
	echo performance >/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
	mount --bind /mnt/SDCARD/Roms/PICO8 /mnt/SDCARD/Emus/PICO/PICO8_Wrapper/.lexaloffle/pico-8/carts
	pico8_64 -splore -preblit_scale 3
	umount /mnt/SDCARD/Apps/pico/.lexaloffle/pico-8/carts
	echo ondemand >/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
}

main "$1"
