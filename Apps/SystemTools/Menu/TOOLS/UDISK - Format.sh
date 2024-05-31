#!/bin/sh

LD_LIBRARY_PATH="/mnt/SDCARD/System/lib:/usr/trimui/lib:$LD_LIBRARY_PATH"

/mnt/SDCARD/System/bin/sdl2imgshow \
    -i "/mnt/SDCARD/trimui/res/crossmix-os/bg-info.png" \
    -f "/mnt/SDCARD/System/resources/DejaVuSans.ttf" \
    -s 25 \
    -c "220,220,220" \
    -t "UDISK formating: press A to continue, B to cancel." &
sleep 1
pkill -f sdl2imgshow

button=$("/mnt/SDCARD/System/usr/trimui/scripts/getkey.sh" B A)

if [ "$button" = "B" ]; then
    echo "UDISK formating canceled"
    /mnt/SDCARD/System/bin/sdl2imgshow \
        -i "/mnt/SDCARD/trimui/res/crossmix-os/bg-info.png" \
        -f "/mnt/SDCARD/System/resources/DejaVuSans.ttf" \
        -s 25 \
        -c "220,220,220" \
        -t "UDISK formating: canceled." &
    sleep 0.5
    pkill -f sdl2imgshow
    exit
fi

/mnt/SDCARD/System/bin/sdl2imgshow \
    -i "/mnt/SDCARD/trimui/res/crossmix-os/bg-info.png" \
    -f "/mnt/SDCARD/System/resources/DejaVuSans.ttf" \
    -s 25 \
    -c "220,220,220" \
    -t "UDISK formating..." &

LOG_FILE="/mnt/SDCARD/Apps/SystemTools/Logs/UDISK - Format.log"
UDISK_DEV="/dev/by-name/UDISK"
UDISK_MOUNT="/mnt/UDISK"
SOURCE_DIR="/mnt/UDISK"
BACKUP_DIR="/mnt/SDCARD/Apps/SystemTools/Ressources/UDISK_Backup"
DEST_DIR="/mnt/UDISK"
FILES="joypad.config joypad_right.config system.json"

exec >"$LOG_FILE" 2>&1

echo "=============================================="
date '+%Y-%m-%d %H:%M:%S'
echo "Starting file copy operations..."
echo "=============================================="

if [ ! -d "$BACKUP_DIR" ]; then
    echo "Creating backup directory: $BACKUP_DIR"
    mkdir -p "$BACKUP_DIR"
fi

for file in $FILES; do
    if [ -f "$SOURCE_DIR/$file" ]; then
        echo "Backing up $file to $BACKUP_DIR"
        cp -f "$SOURCE_DIR/$file" "$BACKUP_DIR/"
        sync
    else
        echo "File does not exist in source: $file"
    fi
done

echo "Backup to SDCARD completed."

echo "Attempting to unmount $UDISK_MOUNT..."
sync
umount "$UDISK_MOUNT" && echo "$UDISK_MOUNT unmounted successfully." || echo "Failed to unmount $UDISK_MOUNT."

if [ -e "$UDISK_DEV" ]; then
    echo "Formatting $UDISK_DEV to FAT32..."
    mkfs.vfat -F 32 "$UDISK_DEV" && echo "Format to FAT32 successful." || echo "Failed to format $UDISK_DEV."
else
    echo "$UDISK_DEV does not exist."
    exit 1
fi

echo "Remounting $UDISK_DEV to $UDISK_MOUNT..."
mount -t vfat "$UDISK_DEV" "$UDISK_MOUNT" && echo "$UDISK_DEV mounted successfully to $UDISK_MOUNT." || echo "Failed to mount $UDISK_DEV to $UDISK_MOUNT."

sleep 2

for file in $FILES; do
    if [ -f "$BACKUP_DIR/$file" ]; then
        echo "Restoring $file from $BACKUP_DIR to $DEST_DIR"
        cp -f "$BACKUP_DIR/$file" "$DEST_DIR/"
        sync
    else
        echo "Backup file does not exist: $file"
    fi
done

echo "File restoration completed."

rm -r /usr/trimui/apps/usb_storage
if [ $? -eq 0 ]; then
    echo "Successfully removed usb_storage from /usr/trimui/apps."
else
    echo "Failed to remove usb_storage from /usr/trimui/apps."
fi

unzip /mnt/SDCARD/Apps/SystemTools/Ressources/usb_storage.zip -d /usr/trimui/apps/
if [ $? -eq 0 ]; then
    echo "Successfully copied usb_storage to /usr/trimui/apps."
else
    echo "Failed to copy usb_storage to /usr/trimui/apps."
fi

sync

sleep 0.3
pkill -f sdl2imgshow

/mnt/SDCARD/System/bin/sdl2imgshow \
    -i "/mnt/SDCARD/trimui/res/crossmix-os/bg-info.png" \
    -f "/mnt/SDCARD/System/resources/DejaVuSans.ttf" \
    -s 25 \
    -c "220,220,220" \
    -t "Rebooting..." &
sleep 2
pkill -f sdl2imgshow

reboot &

sleep 30
