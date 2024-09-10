#!/usr/bin/env sh

sed -i 's/^{.*,"label/{"label/' /mnt/SDCARD/Roms/favourite2.json
awk '{
  match ($0, /sublabel":"([^"]*)"/, sublabel)
  match ($0, /rompath":"([^"]*)"/, rompath)
  if (sublabel[1] ~ /^[[:space:]]*$/) {
    match(rompath[1], /.*\/Roms\/([^\/]+)\/.*/, emudir)
    gsub(/sublabel":"[^"]*"/, "sublabel\":\"" emudir[1] "\"")
  }
  print
}' /mnt/SDCARD/Roms/favourite2.json >/tmp/favourite2.json
mv /tmp/favourite2.json /mnt/SDCARD/Roms/favourite2.json
