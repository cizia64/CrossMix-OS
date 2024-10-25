#!/bin/sh
source /mnt/SDCARD/System/usr/trimui/scripts/common_launcher.sh
cpufreq.sh performance 2 7

Gamename="$(basename "$1" .zip)"
cfg_override="/mnt/SDCARD/RetroArch/.retroarch/config/FinalBurn Neo/tate.cfg"
remap_dir="/mnt/SDCARD/RetroArch/.retroarch/config/remaps/tate/FinalBurn Neo"

cp "$remap_dir/tate.rmp" "$remap_dir/$Gamename.rmp"

cd "$RA_DIR"

HOME=$RA_DIR/ $RA_DIR/ra64.trimui -v -L $RA_DIR/.retroarch/cores/fbneo_libretro.so "$1" --appendconfig "$cfg_override"

rm "$remap_dir/$Gamename.rmp"
