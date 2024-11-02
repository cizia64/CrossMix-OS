#!/usr/bin/env sh

/mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "Fixing favorites..."
set -eu

ROMS_DIR=/mnt/SDCARD/Roms
FAV_FILE=favourite2.json

cd $ROMS_DIR
cp $FAV_FILE $FAV_FILE.unfixed

sed -i 's/^{.*,"label/{"label/' "$FAV_FILE"
awk '{
  match ($0, /sublabel":"([^"]*)"/, sublabel)
  match ($0, /rompath":"([^"]*)"/, rompath)
  if (sublabel[1] ~ /^[[:space:]]*$/) {
    match(rompath[1], /.*\/Roms\/([^\/]+)\/.*/, emudir)
    gsub(/sublabel":"[^"]*"/, "sublabel\":\"" emudir[1] "\"")
  }
  print
}' $FAV_FILE >favourite2_fixed.json
mv favourite2_fixed.json $FAV_FILE

sync
sleep 1
