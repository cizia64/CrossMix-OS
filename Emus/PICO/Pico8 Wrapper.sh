#!/bin/sh
source /mnt/SDCARD/System/usr/trimui/scripts/common_launcher.sh
export picodir=/mnt/SDCARD/Emus/PICO/PICO8_Wrapper
cpufreq.sh ondemand 3 6

cd $picodir
export PATH=$PATH:$PWD/bin
export HOME=$picodir
export PATH=${picodir}:$PATH
export LD_LIBRARY_PATH="$picodir/lib:/usr/lib:$LD_LIBRARY_PATH"

if ! [ -f /mnt/SDCARD/Emus/PICO/PICO8_Wrapper/bin/pico8_64 ] || ! [ -f /mnt/SDCARD/Emus/PICO/PICO8_Wrapper/bin/pico8.dat ]; then
	LD_LIBRARY_PATH="/mnt/SDCARD/System/lib:/usr/trimui/lib:$LD_LIBRARY_PATH"
	/mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "To use the official PICO-8, you need to add your purchased binaries (pico8_64 and pico8.dat)." -fs 25 -t 5
fi

# To support MENU + START exit shortcut
/mnt/SDCARD/System/bin/thd --triggers /mnt/SDCARD/Emus/PICO/PICO8_Wrapper/cfg/thd.conf /dev/input/event3 &


mount --bind /mnt/SDCARD/Roms/PICO8 /mnt/SDCARD/Emus/PICO/PICO8_Wrapper/.lexaloffle/pico-8/carts
pico8_64 -preblit_scale 3 -run "$1"

kill -9 $(pidof thd)
umount /mnt/SDCARD/Apps/pico/.lexaloffle/pico-8/carts
