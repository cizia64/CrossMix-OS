#!/bin/sh

echo $0 $*


LD_LIBRARY_PATH="/mnt/SDCARD/System/lib:/usr/trimui/lib:/mnt/SDCARD/System/bin/imagemagick/lib64:$LD_LIBRARY_PATH"
export MAGICK_CODER_MODULE_PATH="/mnt/SDCARD/System/bin/imagemagick/lib64/ImageMagick-6.9.10/modules-Q16/coders/"

LOG_FILE="/mnt/SDCARD/Apps/BootLogo/BootLogo.log"

exec >>$LOG_FILE 2>&1
echo "===================================="
date +'%Y-%m-%d %H:%M:%S'
echo "===================================="
silent=0
input_file="$1"
filename=$(basename "$input_file")
extension="${filename##*.}"
filename="${filename%.*}"

# Manage 2 cases : bmp directly in parameter to this script or from the BootLogo app
if [ "$extension" = "bmp" ]; then
    SOURCE_FILE="$input_file"
    silent=1
else
    SOURCE_FILE="/mnt/SDCARD/Apps/BootLogo/Images/${filename}.bmp"
fi


if [ $? -ne 0 ]; then
	echo "Failed to mount $TARGET_PARTITION."
	sync
	exit 1
fi

echo "Source file: $SOURCE_FILE"

if [ -f "$SOURCE_FILE" ]; then
	echo "Moving $SOURCE_FILE to $MOUNT_POINT/bootlogo.bmp..."

	resolution=$(/mnt/SDCARD/System/bin/gm identify -format "%w %h" "$SOURCE_FILE")
	width=$(echo "$resolution" | cut -d' ' -f1)
	height=$(echo "$resolution" | cut -d' ' -f2)

	echo "Resolution of \"$filename\" is: ${width}x${height}"

	################# Check if the resolution is 1280x720 #################
	if [ "$width" -gt 1280 ] || [ "$height" -gt 720 ]; then
		echo "The image \"$filename\" is too large. Quitting without flash."
		[ "$silent" -eq 0 ] && /mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -i "$SOURCE_FILE" -m "Image resolution is larger than expected, exiting. (${width}x${height} instead of 1280x720)" -t 5 -c "220,0,0"
		exit 1
	elif [ "$width" -lt 1280 ] || [ "$height" -lt 720 ]; then
		echo "The image \"$filename\" is too small. Not recommended but should be OK."
		[ "$silent" -eq 0 ] && /mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -i "$SOURCE_FILE" -m "Image resolution is smaller than expected. (${width}x${height} instead of 1280x720)" -t 5 -c "220,0,0"
	else
		echo "The image \"$filename\" has a resolution of 1280x720. Let's continue !"
	fi

	################# Check if file type is BMP #################
	file_type=$(/mnt/SDCARD/System/bin/gm identify -format "%m" "$SOURCE_FILE")
	if [ "$file_type" = "BMP" ]; then
		echo "\"$filename\" is a BMP image. Let's continue !"
	else
		echo "\"$filename\" is not a BMP image. Quitting without flash."
		sync
		[ "$silent" -eq 0 ] && /mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -i "$SOURCE_FILE" -c "220,0,0" -m "Image is not a real .bmp file, check the format and convert it." -t 5 -c "220,0,0"
		exit 1
	fi

	################# Check file size #################
	max_size_bytes=$((6 * 1024 * 1024))
	file_size=$(stat -c "%s" "$SOURCE_FILE")
	echo "Size of $file is: $file_size bytes"

	if [ "$file_size" -lt "$max_size_bytes" ]; then
		echo "\"$filename\" has size less than 6MB. Let's continue !"
	else
		echo "\"$filename\" exceeds 6MB. Quitting without flash."
		[ "$silent" -eq 0 ] && /mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -i "$SOURCE_FILE" -m "Image file is too big (6MB maximum)" -t 6 -c "220,0,0"
	fi

	################# Flashing logo #################

	echo "Mounting $TARGET_PARTITION to $MOUNT_POINT..."
	mkdir -p $MOUNT_POINT
	mount $TARGET_PARTITION $MOUNT_POINT


	[ "$silent" -eq 0 ] && /mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -i "$SOURCE_FILE" -m "Flashing logo..." -fs 100 -t 2.5

	cp "$SOURCE_FILE" "$MOUNT_POINT/bootlogo.bmp"
	if [ $? -ne 0 ]; then
		echo "Failed to move bootlogo file."
	else
		echo "Bootlogo file moved successfully."
	fi
	sync
	if ! cmp -s "$SOURCE_FILE" "$MOUNT_POINT/bootlogo.bmp"; then
		# The flashed file is different from the source, we restore the default logo
		rm "$MOUNT_POINT/bootlogo.bmp"
		cp "/mnt/SDCARD/Apps/BootLogo/Images/- Default Trimui.bmp" "$MOUNT_POINT/bootlogo.bmp"
	fi
	sync
	sleep 0.5
	sync
	[ "$silent" -eq 0 ] && cp /mnt/SDCARD/Apps/BootLogo/GoBackTo_Apps.json /tmp/state.json
	sync

	################# End of flash #################
	
	[ "$silent" -eq 0 ] && /mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -i "$SOURCE_FILE" -m "Flash done !" -c "0,220,0" -fs 100 -t 0.5

else
	echo "Source file does not exist."
	exit 1
fi

if [ $? -ne 0 ]; then
	echo "Failed to move file."
else
	echo "File moved successfully."
fi

echo "Unmounting $TARGET_PARTITION..."
umount $TARGET_PARTITION

rmdir $MOUNT_POINT

echo "Script completed."

# we don't memorize System Tools scripts in recent list
if [ "$silent" -eq 0 ]; then
	recentlist=/mnt/SDCARD/Roms/recentlist.json
	sed -i '/_BootLogo\/launch.sh/d' $recentlist
fi
sync
