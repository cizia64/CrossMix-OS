#!/bin/sh
source /mnt/SDCARD/System/usr/trimui/scripts/launchers/common_launcher.sh
cpufreq.sh conservative 0 6

cd "$RA_DIR"

case "$@" in
    *.neo) CORE_PATH=.retroarch/cores/geolith_libretro.so ;; # fall back to geolith for terraonion .neo
    *)     
        fba=$(grep -i "dowork 0x" "/tmp/log/messages" | tail -n 1 | grep -i "FB ALPHA 2012")
        if [ -n "$fba" ]; then # fb alpha 2012 selected
            CORE_PATH=.retroarch/cores/fbalpha2012_neogeo_libretro.so
        else
            CORE_PATH=.retroarch/cores/fbneo_libretro.so
        fi
        ;;
esac

HOME="$PWD" ./ra64.trimui -v $NET_PARAM -L "$CORE_PATH" "$@"

#HOME="$PWD" ./ra64.trimui -v $NET_PARAM -L .retroarch/cores/fbalpha2012_neogeo_libretro.so "$@"
#HOME="$PWD" ./ra64.trimui -v $NET_PARAM -L $EMU_DIR/fbalpha2012_neogeo_libretro.so "$@"
#HOME="$PWD" ./ra64.trimui -v $NET_PARAM -L $EMU_DIR/fbalpha2012_libretro.so "$@"
#HOME="$PWD" ./ra64.trimui -v $NET_PARAM -L .retroarch/cores/geolith_libretro.so "$@"
#HOME="$PWD" $RA_DIR/retroarch -v $NET_PARAM -L $EMU_DIR/fbalpha2012_neogeo_libretro.so "$@"
