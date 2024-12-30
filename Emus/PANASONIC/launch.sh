#!/bin/sh
source /mnt/SDCARD/System/usr/trimui/scripts/common_launcher.sh
cpufreq.sh performance 2 7

# Check BIOS files presence
BIOS_DIR="/mnt/SDCARD/BIOS"
required_bios_files="panafz1.bin panafz10.bin panafz10-norsa.bin panafz10e-anvil.bin panafz10e-anvil-norsa.bin panafz1j.bin panafz1j-norsa.bin goldstar.bin sanyotry.bin 3do_arcade_saot.bin"
bios_found=false

for bios_file in $required_bios_files; do
  if [ -f "$BIOS_DIR/$bios_file" ]; then
    bios_found=true
    break
  fi
done

if [ "$bios_found" = false ]; then
  /mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -i bg-exit.png -m "No bios found, 3DO will probably not work (black screen)." -k " "
else
  echo "At least one of the required BIOS file is present in $BIOS_DIR."
fi

cd $RA_DIR/

HOME=$RA_DIR/ $RA_DIR/ra64.trimui -v -L $RA_DIR/.retroarch/cores/opera_libretro.so "$@" &
activities add "$1" $!
