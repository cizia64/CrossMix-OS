#!/bin/sh
export EMU_DIR="/mnt/SDCADRD/Emus/PICO"
export picodir=/mnt/SDCARD/Emus/PICO/PICO8_Wrapper
cd $picodir
export PATH=$PATH:$PWD/bin
export HOME=$picodir
export PATH=${picodir}:$PATH
export LD_LIBRARY_PATH="$picodir/lib:/usr/lib:$LD_LIBRARY_PATH"

if ! [ -f /mnt/SDCARD/Emus/PICO/PICO8_Wrapper/bin/pico8_64 ] || ! [ -f /mnt/SDCARD/Emus/PICO/PICO8_Wrapper/bin/pico8.dat ]; then
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

main() {
	$EMU_DIR/cpufreq.sh
	mount --bind /mnt/SDCARD/Roms/PICO8 /mnt/SDCARD/Emus/PICO/PICO8_Wrapper/.lexaloffle/pico-8/carts
	pico8_64 -splore -preblit_scale 3
	umount /mnt/SDCARD/Apps/pico/.lexaloffle/pico-8/carts
}

main "$1"
