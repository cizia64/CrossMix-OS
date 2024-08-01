#!/bin/sh
echo "===================================="
echo $0 $*
cd "$(dirname "$0")"

source /mnt/SDCARD/System/usr/trimui/scripts/common_launcher.sh
./cpufreq.sh

cd /mnt/SDCARD/RetroArch

/mnt/SDCARD/System/usr/trimui/scripts/set_ra_cfg.sh \
	"$PWD/.retroarch/config/Genesis Plus GX Wide/MD.cfg" \
	"input_overlay_enable" "false"

HOME="$PWD" ./ra64.trimui -v $NET_PARAM -L .retroarch/cores/genesis_plus_gx_wide_libretro.so "$@"
