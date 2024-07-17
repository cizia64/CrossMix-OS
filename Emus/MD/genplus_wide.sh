#!/bin/sh
echo "===================================="
echo $0 $*
source /mnt/SDCARD/System/usr/trimui/scripts/common_launcher.sh
RA_DIR=/mnt/SDCARD/RetroArch
EMU_DIR=/mnt/SDCARD/Emus/MD

/mnt/SDCARD/System/usr/trimui/scripts/set_ra_cfg.sh "/mnt/SDCARD/RetroArch/.retroarch/config/Genesis Plus GX Wide/MD.cfg"  "input_overlay_enable" "false"

cd $RA_DIR/

$EMU_DIR/cpufreq.sh

HOME=$RA_DIR/ $RA_DIR/ra64.trimui -v $NET_PARAM -L $RA_DIR/.retroarch/cores/genesis_plus_gx_wide_libretro.so "$@"
