#!/usr/bin/env sh

if ! grep -q "/mnt/SDCARD/System/bin" /etc/profile; then
    echo 'export PATH="/mnt/SDCARD/System/usr/trimui/scripts:/mnt/SDCARD/System/bin:/bin:/usr/bin:/usr/trimui/bin"' >>/etc/profile
fi
if ! grep -q "/mnt/SDCARD/System/lib" /etc/profile; then
    echo 'export LD_LIBRARY_PATH="/mnt/SDCARD/System/lib:/lib:/usr/lib:/usr/trimui/lib"' >>/etc/profile
fi

