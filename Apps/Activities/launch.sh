#!/bin/sh
echo $0 $*

export PATH="$PATH:/mnt/SDCARD/System/bin"

skins="$(jq -r '.["theme"]' /mnt/UDISK/system.json)"
backgrounds="$(jq -r '.["BACKGROUNDS"]' /mnt/SDCARD/System/etc/crossmix.json)"
sed -iE 's/^skins_theme=.*$/skins_theme='"${skins#*Themes/}"'
  s/^backgrounds_theme=.*$/backgrounds_theme='"$backgrounds/" data/config.ini
sync

/mnt/SDCARD/System/bin/activities gui # -last