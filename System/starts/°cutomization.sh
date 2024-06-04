#!/bin/sh
export LD_LIBRARY_PATH="/mnt/SDCARD/System/lib:/usr/trimui/lib:$LD_LIBRARY_PATH"
system_json="/mnt/UDISK/system.json"
Current_Theme=$(/usr/trimui/bin/systemval theme)
Current_bg="$Current_Theme/skin/bg.png"
if [ ! -f "$Current_bg" ]; then
	Current_bg="/mnt/SDCARD/trimui/res/skin/transparent.png"
fi

################ CrossMix-OS Version Splashscreen ################

version=$(cat /mnt/SDCARD/System/usr/trimui/crossmix-version.txt)
/mnt/SDCARD/System/bin/sdl2imgshow \
	-i "$Current_bg" \
	-f "/mnt/SDCARD/System/resources/DejaVuSans.ttf" \
	-s 30 \
	-c "220,220,220" \
	-t "CrossMix OS v$version" &

################ CrossMix-OS internal storage Customization ################

if [ ! -e "/usr/trimui/fw_mod_done" ]; then

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

	# Apply default CrossMix theme, sound volume, and grid view
	cp /mnt/SDCARD/System/usr/trimui/scripts/MainUI_default_system.json /mnt/UDISK/system.json
	# sed -i "s|\"theme\":.*|\"theme\": \"/mnt/SDCARD/Themes/CrossMix - OS/\",|" "$system_json"

	################ CrossMix-OS SD card Customization ################

	# Sorting Themes Alphabetically
	"/mnt/SDCARD/Apps/SystemTools/Menu/THEME/Sort Themes Alphabetically.sh" -s

	# Game tab by default
	"/mnt/SDCARD/Apps/SystemTools/Menu/USER INTERFACE##START TAB (value)/Tab Game.sh" -s

	# Displaying only Emulators with roms if the Emus list is not already customized
	if [ ! -e "/mnt/SDCARD/Emus/show.json" ]; then
		/mnt/SDCARD/Apps/EmuCleaner/launch.sh -s
	fi

	################ Flash boot logo ################

	SOURCE_FILE="/mnt/SDCARD/Apps/BootLogo/Images/- CrossMix-OS.bmp"
	TARGET_PARTITION="/dev/mmcblk0p1"
	MOUNT_POINT="/mnt/emmcblk0p1"

	echo "Mounting $TARGET_PARTITION to $MOUNT_POINT..."
	mkdir -p $MOUNT_POINT
	mount $TARGET_PARTITION $MOUNT_POINT

	if [ $? -ne 0 ]; then
		echo "Failed to mount $TARGET_PARTITION."
	fi

	if [ -f "$SOURCE_FILE" ]; then
		echo "Moving "$SOURCE_FILE" to $MOUNT_POINT/bootlogo.bmp..."
		cp "$SOURCE_FILE" $MOUNT_POINT/bootlogo.bmp
		if [ $? -ne 0 ]; then
			echo "Failed to move bootlogo file."
		else
			echo "Bootlogo file moved successfully."
		fi
		sync
		sync
		sleep 0.3
		sync
	else
		echo "Source bootlogo file does not exist."
	fi

	echo "Unmounting $TARGET_PARTITION..."
	umount $TARGET_PARTITION
	rmdir $MOUNT_POINT

	touch "/usr/trimui/fw_mod_done"
	sync
fi

######################### CrossMix-OS at each boot #########################

# Apply current led configuration
/mnt/SDCARD/System/etc/led_config.sh &

pkill -f sdl2imgshow
