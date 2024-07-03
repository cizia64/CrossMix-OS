#!/bin/sh

IP=$(ip route get 1 2>/dev/null | awk '{print $NF;exit}')
echo "Current IP address: $IP"

/mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -i bg-exit.png -m "Current IP address: $IP" - k " "
