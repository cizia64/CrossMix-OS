#!/bin/sh
source /mnt/SDCARD/System/usr/trimui/scripts/common_launcher.sh
cpufreq.sh ondemand 2 6

cd $RA_DIR/

case "$@" in
    *.neo) CORE_PATH=$RA_DIR/.retroarch/cores/geolith_libretro.so ;; # fall back to geolith for terraonion .neo
    *)     
        fba=$(grep -i "dowork 0x" "/tmp/log/messages" | tail -n 1 | grep -i "FB ALPHA 2012")
        if [ -n "$fba" ]; then # fb alpha 2012 selected
            CORE_PATH=$RA_DIR/.retroarch/cores/fbalpha2012_neogeo_libretro.so
        else
            CORE_PATH=$RA_DIR/.retroarch/cores/fbneo_libretro.so
        fi
        ;;
esac

HOME=$RA_DIR/ $RA_DIR/ra64.trimui -v -L $CORE_PATH "$@"
