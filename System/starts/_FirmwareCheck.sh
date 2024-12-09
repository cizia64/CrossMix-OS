#!/bin/sh

################ check min Firmware version required ################

CrossMixFWfile="/mnt/SDCARD/trimui/firmwares/MinFwVersion.txt"

Current_FW_Revision=$(grep 'DISTRIB_DESCRIPTION' /etc/openwrt_release | cut -d '.' -f 3)
Required_FW_Revision=$(sed -n '2p' "$CrossMixFWfile")

echo "Current FW Revision: $Current_FW_Revision"
echo "Required FW Revision: $Required_FW_Revision"

if [ -z "$Current_FW_Revision" ] || [ -z "$Required_FW_Revision" ]; then

	echo "Firmware check not possible."

else

	if [ "$Current_FW_Revision" -lt "$Required_FW_Revision" ]; then

		pgrep -f /usr/trimui/bin/trimui_inputd >/dev/null || /usr/trimui/bin/trimui_inputd & # we need input

		Current_FW_Version="$(cat /etc/version)"
		Required_FW_Version=$(sed -n '1p' "$CrossMixFWfile")

		Echo "Current firmware ($Current_FW_Version - $Current_FW_Revision) must be updated to $Required_FW_Version - $Required_FW_Revision to support CrossMix OS v$version."

		# Install new busybox from PortMaster, credits : https://github.com/kloptops/TRIMUI_EX

		Current_busybox_crc=$(crc32 "/bin/busybox" | awk '{print $1}')
		target_busybox_crc=$(crc32 "/mnt/SDCARD/System/usr/trimui/scripts/busybox" | awk '{print $1}')

		if [ "$Current_busybox_crc" != "$target_busybox_crc" ]; then

			# make some place
			rm -rf /usr/trimui/apps/zformatter_fat32/
			rm -rf /usr/trimui/res/sound/bgm2.mp3
			swapoff -a
			rm -rf /swapfile
			cp "/mnt/SDCARD/trimui/res/skin/bg.png" "/usr/trimui/res/skin/"

			cp -vf /bin/busybox /mnt/SDCARD/System/bin/busybox.bak
			/mnt/SDCARD/System/bin/rsync /mnt/SDCARD/System/usr/trimui/scripts/busybox /bin/busybox
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

		button=$(/mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -i "/mnt/SDCARD/trimui/firmwares/FW_Informations.png" -m "Current FW version: $Current_FW_Version - $Current_FW_Revision                Required FW version: $Required_FW_Version - $Required_FW_Revision" -fs 28 -k "A")

		button=$(/mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -i "/mnt/SDCARD/trimui/firmwares/FW_Update_Instructions.png" -k "A B")

		if [ "$button" = "A" ]; then

			/mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -i "/mnt/SDCARD/trimui/firmwares/FW_Copy.png" -m "Please wait, copying Firmware v$Required_FW_Version - $Required_FW_Revision..."

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
				/mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -i bg-exit.png -m "Firmware CRC check has failed, canceling update." -k A
			fi

			sleep 1
			sync
			poweroff
			sleep 30
			exit
		else
			rm -f "/mnt/SDCARD/trimui_tg5040.awimg"
		fi

	else
		echo "Firmware version $Current_FW_Revision OK."
		rm -f "/mnt/SDCARD/trimui_tg5040.awimg"

	fi
fi

################ check if a CrossMix-OS update is available ################

# Set PATH and library path
PATH="/mnt/SDCARD/System/bin:/mnt/SDCARD/System/usr/trimui/scripts/:$PATH"
export LD_LIBRARY_PATH="/mnt/SDCARD/System/lib:/usr/trimui/lib:$LD_LIBRARY_PATH"

# Find the update file
UPDATE_FILE=$(find /mnt/SDCARD -maxdepth 1 -name "CrossMix-OS_v*.zip" -print -quit)

if [ -n "$UPDATE_FILE" ]; then
	/usr/trimui/bin/trimui_inputd & # we need input
	echo "CrossMix-OS install file found: $UPDATE_FILE"
	initial_version=$(cat /mnt/SDCARD/System/usr/trimui/crossmix-version.txt)
	update_version=$(echo "$UPDATE_FILE" | awk -F'_v|\.zip' '{print $2}')

	# Compare the versions
	if [ "$(echo "$update_version" | tr -d '.')" -gt "$(echo "$initial_version" | tr -d '.')" ]; then
		echo "The CrossMix update file (v$update_version) is greater than the current version installed ($initial_version)."

		minspace=$((20 * 1024))
		rootfs_space=$(df / | awk 'NR==2 {print $4}')
		if [ "$rootfs_space" -lt "$minspace" ]; then
			echo "Error: Available space on internal storage is less than 20 MB"
			infoscreen.sh -m "CrossMix-OS update v$update_version found. Not enough space on internal storage to update." -k "A B START MENU" -fs 30
			exit 1
		else
			echo "Available space on / is sufficient: ${rootfs_space} KB"
		fi

		if [ ! -f "/mnt/SDCARD/trimui/res/crossmix-os/bg-info.png" ] ||
			[ ! -f "/mnt/SDCARD/System/bin/sdl2imgshow" ] ||
			[ ! -f "/mnt/SDCARD/System/usr/trimui/scripts/crossmix_update.sh" ] ||
			[ ! -f "/mnt/SDCARD/System/usr/trimui/scripts/getkey.sh" ] ||
			[ ! -f "/mnt/SDCARD/System/usr/trimui/scripts/common_launcher.sh" ] ||
			[ ! -f "/mnt/SDCARD/System/usr/trimui/scripts/evtest" ]; then
			echo "One or more required files are missing."
			/mnt/SDCARD/System/bin/7zz -aoa x "$UPDATE_FILE" \
				-o"/mnt/SDCARD" \
				-i"!System/bin/*" \
				-i"!System/lib/*" \
				-i"!System/resources/*" \
				-i"!System/usr/trimui/scripts/*" \
				-i"!trimui/res/crossmix-os/*"
			sync
		fi

		button=$(infoscreen.sh -m "CrossMix-OS update v$update_version found. Press A to install, B to cancel." -k "A B")
		if [ "$button" = "A" ]; then
			/mnt/SDCARD/System/bin/7zz e "$UPDATE_FILE" "System/usr/trimui/scripts/crossmix_update.sh" -o/tmp -y
			chmod a+x "/tmp/crossmix_update.sh"
			cp /mnt/SDCARD/System/bin/text_viewer /tmp
			infoscreen.sh -m "Updating CrossMix to v$update_version" -t 1
			pkill -9 preload.sh
			pkill -9 runtrimui.sh
			/tmp/text_viewer -s "/tmp/crossmix_update.sh" -f 25 -t "                            CrossMix-OS Update v$update_version                                      "
		fi
	else
		echo "The CrossMix update version ($update_version) is not greater than the current version ($initial_version)."
	fi
else
	echo "No CrossMix update file found."
fi

