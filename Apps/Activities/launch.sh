#!/bin/sh
echo $0 $*

cd "$(dirname "$0")"
read -r device < /etc/trimui_device.txt
sed -iE 's/^device=.*$/device='"$device/" data/config.ini

/mnt/SDCARD/System/bin/activities gui
