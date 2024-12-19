#!/bin/sh
echo $0 $*
progdir=$(dirname "$0")
cd $progdir
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/mnt/SDCARD/System/usr/trimui/scripts:$progdir
devsd=/dev/mmcblk1
echo "=============================================="
echo "============== MTP Storage Mode  ============="
echo "=============================================="

echo 1 >/tmp/stay_awake

if [ -e /dev/mmcblk1p1 ]; then
    devsd="/dev/mmcblk1p1"
fi

echo SD dev:$devsd

if ! (umount /mnt/UDISK && mount --bind /mnt/SDCARD /mnt/UDISK); then
    infoscreen.sh -m "Failed to prepare folders. Exit."
    exit 1
fi

cd /usr/trimui/apps/usb_storage
/bin/setusbconfig mtp
chmod 777 /usr/trimui/apps/usb_storage/usb_storage
/usr/trimui/apps/usb_storage/usb_storage

sync
/bin/setusbconfig adb

umount /mnt/UDISK && mount /dev/by-name/UDISK /mnt/UDISK

rm /tmp/stay_awake
