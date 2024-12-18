#!/bin/sh

LD_LIBRARY_PATH="/mnt/SDCARD/System/lib:/usr/trimui/lib:$LD_LIBRARY_PATH"


button=$(/mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "UDISK formating: press A to continue, B to cancel." -fs 25 -k "A B")

if [ "$button" = "B" ]; then
    echo "UDISK formating canceled"
	/mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "UDISK formating: canceled." -t 0.5
    exit
fi

/mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "UDISK formating..." -fs 25

LOG_FILE="/mnt/SDCARD/Apps/SystemTools/Logs/UDISK - Format.log"
UDISK_DEV="/dev/by-name/UDISK"
UDISK_MOUNT="/mnt/UDISK"
SOURCE_DIR="/mnt/UDISK"
BACKUP_DIR="/mnt/SDCARD/Apps/SystemTools/Resources/UDISK_Backup"
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

sync

sleep 0.3

/mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "Rebooting..." -t 2

reboot &

sleep 30
