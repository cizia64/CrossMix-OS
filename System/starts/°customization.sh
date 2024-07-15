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
/mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -i "$Current_bg" -m "CrossMix OS v$version"

################ CrossMix-OS internal storage Customization ################
FW_patched_version=$(cat /usr/trimui/crossmix-version.txt)

if [ "$version" != "$FW_patched_version" ]; then
	# Removing duplicated app
	rm -rf /usr/trimui/apps/zformatter_fat32/

	# add Pl language + Fr and En mods
	if [ ! -e "/usr/trimui/res/skin/pl.lang" ]; then
		cp "/mnt/SDCARD/trimui/res/lang/"*.lang "/usr/trimui/res/lang/"
		cp "/mnt/SDCARD/trimui/res/lang/"*.short "/usr/trimui/res/lang/"
		cp "/mnt/SDCARD/trimui/res/lang/"*.png "/usr/trimui/res/skin/"
	fi

	# custom shutdown script for "Resume at Boot"
	cp "/mnt/SDCARD/System/usr/trimui/bin/kill_apps.sh" "/usr/trimui/bin/kill_apps.sh"
	chmod a+x "/usr/trimui/bin/kill_apps.sh"

	# custom shutdown script, will be called by MainUI
	cp "/mnt/SDCARD/System/bin/shutdown" "/usr/bin/poweroff"
	chmod a+x "/usr/bin/poweroff"

	# modifying default theme to impact all other themes (Better game image background)
	mv "/usr/trimui/res/skin/ic-game-580.png" "/usr/trimui/res/skin/ic-game-580_old.png"
	cp "/mnt/SDCARD/trimui/res/skin/ic-game-580.png" "/usr/trimui/res/skin/ic-game-580.png"

	# modifying FN cpu script (don't force slow cpu, only force high speed when FN is set to ON) (and we set it as default)
	cp /mnt/SDCARD/System/usr/trimui/res/apps/fn_editor/com.trimui.cpuperformance.sh /usr/trimui/apps/fn_editor/com.trimui.cpuperformance.sh
	cp /mnt/SDCARD/System/usr/trimui/res/apps/fn_editor/com.trimui.cpuperformance.sh /usr/trimui/scene/com.trimui.cpuperformance.sh

	# Apply default CrossMix theme, sound volume, and grid view
	if [ ! -f /mnt/UDISK/system.json ]; then
		cp /mnt/SDCARD/System/usr/trimui/scripts/MainUI_default_system.json /mnt/UDISK/system.json
	else
		/usr/trimui/bin/systemval theme "/mnt/SDCARD/Themes/CrossMix - OS/"
		/usr/trimui/bin/systemval menustylel1 1
		/usr/trimui/bin/systemval bgmvol 10
	fi

	cp /mnt/SDCARD/System/usr/trimui/scripts/MainUI_default_system.json /mnt/UDISK/system.json

	# sed -i "s|\"theme\":.*|\"theme\": \"/mnt/SDCARD/Themes/CrossMix - OS/\",|" "$system_json"

	# we set the customization flag
	rm "/usr/trimui/fw_mod_done"
	echo $version >/usr/trimui/crossmix-version.txt
	sync

	################ CrossMix-OS SD card Customization ################

	# Sorting Themes Alphabetically
	"/mnt/SDCARD/Apps/SystemTools/Menu/THEME/Sort Themes Alphabetically.sh" -s

	# Game tab by default
	"/mnt/SDCARD/Apps/SystemTools/Menu/USER INTERFACE##START TAB (value)/Tab Game.sh" -s

	# Displaying only Emulators with roms
	/mnt/SDCARD/Apps/EmuCleaner/launch.sh -s

	################ Flash boot logo ################
	CrossMixFWfile="/mnt/SDCARD/trimui/firmwares/MinFwVersion.txt"
	Current_FW_Revision=$(grep 'DISTRIB_DESCRIPTION' /etc/openwrt_release | cut -d '.' -f 3)
	Required_FW_Revision=$(sed -n '2p' "$CrossMixFWfile")

	if ! [ "$Current_FW_Revision" -gt "$Required_FW_Revision" ]; then # on firmware hotfix 9 there is less space than before on /dev/mmcblk0p1 so we avoid to flash the logo
		SOURCE_FILE="/mnt/SDCARD/Apps/BootLogo/Images/- CrossMix-OS.bmp"
		"/mnt/SDCARD/Emus/_BootLogo/launch.sh" "$SOURCE_FILE"
	fi
fi

######################### CrossMix-OS at each boot #########################

# Apply current led configuration
/mnt/SDCARD/System/etc/led_config.sh &
