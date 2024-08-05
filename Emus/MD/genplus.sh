#!/bin/sh
echo "===================================="
echo $0 $*
cd "$(dirname "$0")"

source /mnt/SDCARD/System/usr/trimui/scripts/common_launcher.sh
./cpufreq.sh

NET_PARAM=

cd /mnt/SDCARD/RetroArch
HOME="$PWD" ./ra64.trimui -v $NET_PARAM -L .retroarch/cores/genesis_plus_gx_libretro.so "$@"
