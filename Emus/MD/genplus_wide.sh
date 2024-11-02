#!/bin/sh
source /mnt/SDCARD/System/usr/trimui/scripts/common_launcher.sh
cpufreq.sh ondemand 2 6

/mnt/SDCARD/System/usr/trimui/scripts/set_ra_cfg.sh "/mnt/SDCARD/RetroArch/.retroarch/config/Genesis Plus GX Wide/MD.cfg"  "input_overlay_enable" "false"

cd $RA_DIR/

HOME=$RA_DIR/ $RA_DIR/ra64.trimui -v -L $RA_DIR/.retroarch/cores/genesis_plus_gx_wide_libretro.so "$@"
