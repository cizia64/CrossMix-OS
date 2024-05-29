#!/bin/sh
system_json="/mnt/UDISK/system.json"
Current_Theme=$(/usr/trimui/bin/systemval theme)
Current_bg="$Current_Theme/skin/bg.png"
if [ ! -f "$Current_bg" ]; then
	Current_bg="/mnt/SDCARD/trimui/res/skin/transparent.png"
fi

version=$(cat /mnt/SDCARD/System/usr/trimui/crossmix-version.txt)
/mnt/SDCARD/System/bin/sdl2imgshow \
	-i "$Current_bg" \
	-f "/mnt/SDCARD/System/resources/DejaVuSans.ttf" \
	-s 30 \
	-c "220,220,220" \
	-t "CrossMix OS v$version" &
sleep 0.1
pkill -f sdl2imgshow

################ check min Firmware version required ################
FW_VERSION="$(cat /etc/version)"
CrossMix_MinFwVersion=$(cat /mnt/SDCARD/trimui/firmwares/MinFwVersion.txt)
if [ "$(printf '%s\n' "$FW_VERSION" "$CrossMix_MinFwVersion" | sort -V | head -n1)" != "$CrossMix_MinFwVersion" ]; then
	/usr/trimui/bin/trimui_inputd & # we need input
	Echo "Current firmware ($FW_VERSION) must be updated to $CrossMix_MinFwVersion to support CrossMix OS v$version."
	/mnt/SDCARD/System/bin/sdl2imgshow \
		-i "/mnt/SDCARD/trimui/firmwares/FW_Informations.png" \
		-f "/mnt/SDCARD/System/resources/DejaVuSans.ttf" \
		-s 30 \
		-c "220,220,220" \
		-t "Actual FW version: $FW_VERSION                                    Required FW version: $CrossMix_MinFwVersion" &
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
			-t "Please wait, copying Firmware v$CrossMix_MinFwVersion..." &
		FIRMWARE_PATH="/mnt/SDCARD/trimui/firmwares/1.0.4 hotfix - 20240413.awimg.7z"
		/mnt/SDCARD/System/bin/7zz x "$FIRMWARE_PATH" -o"/mnt/SDCARD" -y
		# cp "/mnt/SDCARD/trimui/firmwares/1.0.4 hotfix - 20240413.awimg" "/mnt/SDCARD/trimui_tg5040.awimg"
		sync
		sync
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
	rm -f "/mnt/SDCARD/trimui_tg5040.awimg"

fi

################ CrossMix-OS Customization ################

if [ ! -e "/usr/trimui/fw_mod_done" ]; then
	# add pl language
	if [ ! -e "/usr/trimui/res/skin/pl.lang" ]; then

		cp "/mnt/SDCARD/trimui/res/lang/pl.lang" "/usr/trimui/res/lang/"
		cp "/mnt/SDCARD/trimui/res/lang/pl.lang.short" "/usr/trimui/res/lang/"
		cp "/mnt/SDCARD/trimui/res/lang/lang_pl.png" "/usr/trimui/res/skin/"
	fi

	# custom shutdown script from "Resume at Boot"
	cp "/mnt/SDCARD/System/usr/trimui/bin/kill_apps.sh" "/usr/trimui/bin/kill_apps.sh"

	# modifying default theme to impact all other themes (Better game image background)
	mv "/usr/trimui/res/skin/ic-game-580.png" "/usr/trimui/res/skin/ic-game-580_old.png"
	cp "/mnt/SDCARD/trimui/res/skin/ic-game-580.png" "/usr/trimui/res/skin/ic-game-580.png"

	# modifying FN cpu script (don't force slow cpu, only force high speed when FN is set to ON) (and we set it as default)
	cp /mnt/SDCARD/System/usr/trimui/res/apps/fn_editor/com.trimui.cpuperformance.sh /usr/trimui/apps/fn_editor/com.trimui.cpuperformance.sh
	cp /mnt/SDCARD/System/usr/trimui/res/apps/fn_editor/com.trimui.cpuperformance.sh /usr/trimui/scene/com.trimui.cpuperformance.sh

	# Removing duplicated app
	rm -rf /usr/trimui/apps/zformatter_fat32/

	# Sorting Themes Alphabetically
	"/mnt/SDCARD/Apps/SystemTools/Menu/THEME/Sort Themes Alphabetically.sh" -s

	# Game tab by default
	"/mnt/SDCARD/Apps/SystemTools/Menu/USER INTERFACE##START TAB (value)/Tab Game.sh" -s

	# Apply default CrossMix theme, sound volume, and grid view
	cp /mnt/SDCARD/System/usr/trimui/scripts/MainUI_default_system.json /mnt/UDISK/system.json
	# sed -i "s|\"theme\":.*|\"theme\": \"/mnt/SDCARD/Themes/CrossMix - OS/\",|" "$system_json"

	# Flash logo
	SOURCE_FILE="/mnt/SDCARD/Apps/BootLogo/Images/- CrossMix-OS.bmp"
	TARGET_PARTITION="/dev/mmcblk0p1"
	MOUNT_POINT="/mnt/emmcblk0p1"

	echo "Mounting $TARGET_PARTITION to $MOUNT_POINT..."
	mkdir -p $MOUNT_POINT
	mount $TARGET_PARTITION $MOUNT_POINT

	if [ $? -ne 0 ]; then
		echo "Failed to mount $TARGET_PARTITION."
		exit 1
	fi

	if [ -f $SOURCE_FILE ]; then
		echo "Moving $SOURCE_FILE to $MOUNT_POINT/bootlogo.bmp..."
		cp $SOURCE_FILE $MOUNT_POINT/bootlogo.bmp
		sync
		sync
		sleep 0.3
		sync
	else
		echo "Source bootlogo file does not exist."
		echo "Unmounting $TARGET_PARTITION..."
		umount $TARGET_PARTITION
		rmdir $MOUNT_POINT
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

	touch "/usr/trimui/fw_mod_done"
	sync
fi
