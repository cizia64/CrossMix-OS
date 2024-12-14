#!/bin/sh
echo $0 $*
progdir=$(dirname "$0")
cd $progdir
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/mnt/SDCARD/System/usr/trimui/scripts:$progdir
devsd=/dev/mmcblk1
echo "=============================================="
echo "============== USB Storage Mode  ============="
echo "=============================================="

echo 1 >/tmp/stay_awake

if [ -e /dev/mmcblk1p1 ]; then
    devsd="/dev/mmcblk1p1"
fi

echo SD dev:$devsd

sync

if ! (umount /mnt/SDCARD && umount /mnt/UDISK &&
    mount /dev/mmcblk1p1 /mnt/UDISK); then
    infoscreen.sh -m "Failed to prepare folders. Exit."
    exit 1
fi

cd /usr/trimui/apps/usb_storage
/bin/setusbconfig mtp,adb
chmod 777 /usr/trimui/apps/usb_storage/usb_storage
/usr/trimui/apps/usb_storage/usb_storage

sync
/bin/setusbconfig adb
#echo "" > /sys/devices/platform/sunxi_usb_udc/gadget/lun0/file
#echo "" > /sys/devices/platform/sunxi_usb_udc/gadget/lun1/file

umount /mnt/UDISK && mount -o iocharset=utf8,errors=continue $devsd /mnt/SDCARD &&
    mount /dev/by-name/UDISK /mnt/UDISK

rm /tmp/stay_awake
