#!/bin/sh
echo "===================================="
echo $0 $*
source /mnt/SDCARD/System/usr/trimui/scripts/common_launcher.sh
RA_DIR=/mnt/SDCARD/RetroArch
EMU_DIR=/mnt/SDCARD/Emus/NEOGEO
cd $RA_DIR/

echo performance >/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
echo 1800000 >/sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq

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

HOME=$RA_DIR/ $RA_DIR/ra64.trimui -v $NET_PARAM -L $CORE_PATH "$@"

#HOME=$RA_DIR/ $RA_DIR/ra64.trimui -v $NET_PARAM -L $RA_DIR/.retroarch/cores/fbalpha2012_neogeo_libretro.so "$@"

#HOME=$RA_DIR/ $RA_DIR/ra64.trimui -v $NET_PARAM -L $EMU_DIR/fbalpha2012_neogeo_libretro.so "$@"
#HOME=$RA_DIR/ $RA_DIR/ra64.trimui -v $NET_PARAM -L $EMU_DIR/fbalpha2012_libretro.so "$@"
#HOME=$RA_DIR/ $RA_DIR/ra64.trimui -v $NET_PARAM -L $RA_DIR/.retroarch/cores/geolith_libretro.so "$@"
#HOME=$RA_DIR/ $RA_DIR/retroarch -v $NET_PARAM -L $EMU_DIR/fbalpha2012_neogeo_libretro.so "$@"