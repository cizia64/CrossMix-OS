#!/bin/sh
source /mnt/SDCARD/System/usr/trimui/scripts/common_launcher.sh
cpufreq.sh ondemand 3 6

export picodir=/mnt/SDCARD/Emus/PICO/PICO8_Wrapper
export LD_LIBRARY_PATH="$picodir/lib:/usr/lib:$LD_LIBRARY_PATH"

Rom="$@"
RomPath=$(dirname "$1")
romName=$(basename "$@")
romNameNoExtension=${romName%.*}

cd $picodir
export PATH=$PATH:$PWD/bin
export HOME=$picodir
export PATH=${picodir}:$PATH

if ! [ -f /mnt/SDCARD/Emus/PICO/PICO8_Wrapper/bin/pico8_64 ] || ! [ -f /mnt/SDCARD/Emus/PICO/PICO8_Wrapper/bin/pico8.dat ]; then
	LD_LIBRARY_PATH="/mnt/SDCARD/System/lib:/usr/trimui/lib:$LD_LIBRARY_PATH"
	/mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "To use the official PICO-8, you need to add your purchased binaries (pico8_64 and pico8.dat)." -fs 25 -t 5
	exit
fi

if [ -f "/mnt/SDCARD/Roms/PICO/° Run Splore.launch" ]; then
	mv "/mnt/SDCARD/Roms/PICO/° Run Splore.launch" "/mnt/SDCARD/Roms/PICO/° Run Splore.p8"
	/mnt/SDCARD/System/usr/trimui/scripts/reset_list.sh "PICO"
fi

# To support MENU + START exit shortcut
/mnt/SDCARD/System/bin/thd --triggers /mnt/SDCARD/Emus/PICO/PICO8_Wrapper/cfg/thd.conf /dev/input/event3 &

if [ "$romNameNoExtension" = "° Run Splore" ]; then
	mkdir -p /mnt/SDCARD/Roms/PICO/splore
	mount --bind /mnt/SDCARD/Roms/PICO/splore /mnt/SDCARD/Emus/PICO/PICO8_Wrapper/.lexaloffle/pico-8/bbs/carts
	pico8_64 -splore -preblit_scale 3
	/mnt/SDCARD/System/bin/rsync --stats -av --ignore-existing --include="*/" --include="*.png" --exclude="*" "/mnt/SDCARD/Roms/PICO/splore/" "/mnt/SDCARD/Imgs/PICO/" &
	/mnt/SDCARD/System/usr/trimui/scripts/reset_list.sh "PICO"
	umount /mnt/SDCARD/Emus/PICO/PICO8_Wrapper/.lexaloffle/pico-8/bbs/carts
	sync
else
	pico8_64 -preblit_scale 3 -run "$1"
fi

kill -9 $(pidof thd)
