#!/bin/sh

################ check min Firmware version required ################

CrossMixFWfile="/mnt/SDCARD/trimui/firmwares/MinFwVersion.txt"

Current_FW_Revision=$(grep 'DISTRIB_DESCRIPTION' /etc/openwrt_release | cut -d '.' -f 3)
Required_FW_Revision=$(sed -n '2p' "$CrossMixFWfile")

if [ -z "$Current_FW_Revision" ] || [ -z "$Required_FW_Revision" ]; then
	echo "Firmware check not possible. Exiting."
	exit 1
fi

if [ "$Current_FW_Revision" -lt "$Required_FW_Revision" ]; then
	/usr/trimui/bin/trimui_inputd & # we need input

	Current_FW_Version="$(cat /etc/version)"
	Required_FW_Version=$(sed -n '1p' "$CrossMixFWfile")

	FILE="/bin/busybox"
	LIMIT=819200
	FILESIZE=$(ls -l "$FILE" | awk '{print $5}')
	# Install new busybox from PortMaster, credits : https://github.com/kloptops/TRIMUI_EX

	if [ "$FILESIZE" -lt "$LIMIT" ]; then
		cp -vf /bin/busybox /bin/busybox.bak
		cp -vf /mnt/SDCARD/System/usr/trimui/scripts/busybox /bin/busybox
		ln -vs "/bin/busybox" "/bin/bash"

		# Create missing busybox commands
		for cmd in $(busybox --list); do
			# Skip if command already exists or if it's not suitable for linking
			if [ -e "/bin/$cmd" ] || [ -e "/usr/bin/$cmd" ] || [ "$cmd" = "sh" ]; then
				continue
			fi

			# Create a symbolic link
			ln -vs "/bin/busybox" "/usr/bin/$cmd"
		done

		# Fix weird libSDL location
		for libname in /usr/trimui/lib/libSDL*; do
			linkname="/usr/lib/$(basename "$libname")"
			if [ -e "$linkname" ]; then
				continue
			fi
			ln -vs "$libname" "$linkname"
		done

	fi
	sync

	Echo "Current firmware ($Current_FW_Version - $Current_FW_Revision) must be updated to $Required_FW_Version - $Required_FW_Revision to support CrossMix OS v$version."
	/mnt/SDCARD/System/bin/sdl2imgshow \
		-i "/mnt/SDCARD/trimui/firmwares/FW_Informations.png" \
		-f "/mnt/SDCARD/System/resources/DejaVuSans.ttf" \
		-s 28 \
		-c "220,220,220" \
		-t "Current FW version: $Current_FW_Version - $Current_FW_Revision                Required FW version: $Required_FW_Version - $Required_FW_Revision" &
	sleep 2 # init input_d

	button=$("/mnt/SDCARD/System/usr/trimui/scripts/getkey.sh" A)
	pkill -f sdl2imgshow

	/mnt/SDCARD/System/bin/sdl2imgshow \
		-i "/mnt/SDCARD/trimui/firmwares/FW_Update_Instructions.png" \
		-f "/mnt/SDCARD/System/resources/DejaVuSans.ttf" \
		-s 30 \
		-c "220,220,220" \
		-t " " &

	button=$("/mnt/SDCARD/System/usr/trimui/scripts/getkey.sh" A B)
	pkill -f sdl2imgshow

	if [ "$button" = "A" ]; then
		/mnt/SDCARD/System/bin/sdl2imgshow \
			-i "/mnt/SDCARD/trimui/firmwares/FW_Copy.png" \
			-f "/mnt/SDCARD/System/resources/DejaVuSans.ttf" \
			-s 30 \
			-c "220,220,220" \
			-t "Please wait, copying Firmware v$Required_FW_Version - $Required_FW_Revision..." &

		FIRMWARE_PATH="/mnt/SDCARD/trimui/firmwares/trimui_tg5040_20240413_v1.0.4_hotfix6.7z"
		FIRMWARE_FILE="trimui_tg5040.awimg"
		/mnt/SDCARD/System/bin/7zz x "$FIRMWARE_PATH" -o"/mnt/SDCARD" -y
		# cp "/mnt/SDCARD/trimui/firmwares/1.0.4 hotfix - 20240413.awimg" "/mnt/SDCARD/trimui_tg5040.awimg"
		sync
		sync

		# Extract CRC from the 7z archive
		ARCHIVE_CRC=$(/mnt/SDCARD/System/bin/7zz l "$FIRMWARE_PATH" -slt "$FIRMWARE_FILE" | grep "CRC = " | awk '{print $3}' | tr 'a-f' 'A-F')

		# Calculate CRC of the extracted file
		EXTRACTED_CRC=$(crc32 "/mnt/SDCARD/trimui_tg5040.awimg" | awk '{print $1}' | tr 'a-f' 'A-F')

		# Compare the CRC values
		if [ "$ARCHIVE_CRC" == "$EXTRACTED_CRC" ]; then
			echo "FW CRC check passed: $EXTRACTED_CRC"
		else
			echo "CRC check failed: Archive CRC = $ARCHIVE_CRC, Extracted CRC = $EXTRACTED_CRC"
			pkill -f sdl2imgshow
			/mnt/SDCARD/System/bin/sdl2imgshow \
				-i "/mnt/SDCARD/trimui/res/crossmix-os/bg-exit.png" \
				-f "/mnt/SDCARD/System/resources/DejaVuSans.ttf" \
				-s 30 \
				-c "220,220,220" \
				-t "Firmware CRC check has failed, canceling update." &

			button=$("/mnt/SDCARD/System/usr/trimui/scripts/getkey.sh" A)
			pkill -f sdl2imgshow
			exit

		fi

		pkill -f sdl2imgshow
		sleep 1
		sync
		poweroff
		sleep 30
		exit
	fi
	rm -f "/mnt/SDCARD/trimui_tg5040.awimg"
	pkill -f sdl2imgshow
else
	echo "Firmware version $Current_FW_Revision OK."
	rm -f "/mnt/SDCARD/trimui_tg5040.awimg"

fi
