#!/usr/bin/env sh

if ! grep -q "/mnt/SDCARD/System/bin" /etc/profile; then
    echo 'export PATH="/mnt/SDCARD/System/bin${PATH:+:$PATH}"' >>/etc/profile
fi
if ! grep -q "/mnt/SDCARD/System/lib" /etc/profile; then
    echo 'export LD_LIBRARY_PATH="/mnt/SDCARD/System/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"' >>/etc/profile
fi

