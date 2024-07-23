#!/bin/sh
source /mnt/SDCARD/System/usr/trimui/scripts/launchers/common_launcher.sh
cpufreq.sh conservative 0 6

NET_PARAM=

cd "$RA_DIR"

set_ra_cfg.sh \
	"$PWD/.retroarch/config/Genesis Plus GX Wide/MD.cfg" \
	"input_overlay_enable" "false"

HOME="$PWD" ./ra64.trimui -v $NET_PARAM -L .retroarch/cores/genesis_plus_gx_wide_libretro.so "$@"
