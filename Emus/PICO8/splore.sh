#!/bin/sh
export picodir=/mnt/SDCARD/Apps/pico
cd $picodir
export PATH=$PATH:$PWD/bin
export HOME=$picodir
export PATH=${picodir}:$PATH
export LD_LIBRARY_PATH="$picodir/lib:/usr/lib:$LD_LIBRARY_PATH"
 
 main() {
    #echo 1008000 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq
    echo performance > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
    mount --bind /mnt/SDCARD/Roms/PICO8 /mnt/SDCARD/Apps/pico/.lexaloffle/pico-8/carts
    pico8_64 -run "$1"
    umount /mnt/SDCARD/Apps/pico/.lexaloffle/pico-8/carts
    echo ondemand > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
}

main "$1" 