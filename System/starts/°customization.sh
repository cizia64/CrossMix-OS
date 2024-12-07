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

	if [ -f "/usr/trimui/crossmix-version.txt" ]; then
		CrossMix_Update=1
	else
		CrossMix_Update=0
	fi

	Current_FW_Revision=$(grep 'DISTRIB_DESCRIPTION' /etc/openwrt_release | cut -d '.' -f 3)
	Max_FW_Revision="20240503"

	if [ "$Current_FW_Revision" -le "$Max_FW_Revision" ]; then

		Sha_expected_1ms=c90b9fa722d745a7e827f38dbd409d3cd1ba56f5
		Sha_expected_8ms=3f1b81d668c3f7de2cc0458502326a732d3cb0b2
		Sha_expected_16ms=356b41b0be9d00f361e45303f41f5f1f337e6efc
		Sha_1ms=$(sha1sum /mnt/SDCARD/System/resources/trimui_inputd/1ms | cut -d ' ' -f 1)
		Sha_8ms=$(sha1sum /mnt/SDCARD/System/resources/trimui_inputd/8ms | cut -d ' ' -f 1)
		Sha_16ms=$(sha1sum /mnt/SDCARD/System/resources/trimui_inputd/16ms | cut -d ' ' -f 1)
		if [ "$Sha_expected_1ms" = "$Sha_1ms" ] && [ "$Sha_expected_8ms" = "$Sha_8ms" ] &&
			[ "$Sha_expected_16ms" = "$Sha_16ms" ]; then

			if [ ! -f /usr/trimui/bin/trimui_inputd.bak ]; then
				mv /usr/trimui/bin/trimui_inputd /usr/trimui/bin/trimui_inputd.bak
			fi

			cp /mnt/SDCARD/System/resources/trimui_inputd/1ms /usr/trimui/bin/trimui_inputd.1ms
			cp /mnt/SDCARD/System/resources/trimui_inputd/8ms /usr/trimui/bin/trimui_inputd.8ms
			cp /mnt/SDCARD/System/resources/trimui_inputd/16ms /usr/trimui/bin/trimui_inputd.16ms
			cp /mnt/SDCARD/System/resources/trimui_inputd/16ms /usr/trimui/bin/trimui_inputd

			chmod +x /usr/trimui/bin/trimui_inputd.1ms
			chmod +x /usr/trimui/bin/trimui_inputd.8ms
			chmod +x /usr/trimui/bin/trimui_inputd.16ms
			chmod +x /usr/trimui/bin/trimui_inputd

			cp /mnt/SDCARD/System/resources/preload.sh /usr/trimui/bin/preload.sh
		else
			/mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "Not able to update trimui_inputd, at least one new is missing or corrupted"
		fi

	else

		echo "recent firmware: trimui_inputd will not be updated"

	fi

	# Removing duplicated app
	rm -rf /usr/trimui/apps/zformatter_fat32/

	# making some place in root fs
	rm -rf /usr/trimui/res/sound/bgm2.mp3
	swapoff -a
	rm -rf /swapfile
	mv /bin/busybox.bak /mnt/SDCARD/System/bin 2>/dev/null
	cp "/mnt/SDCARD/trimui/res/skin/bg.png" "/usr/trimui/res/skin/"

	# Increase alsa sound buffer
	# cp "/mnt/SDCARD/System/usr/trimui/etc/asound.conf" "/etc/asound.conf"

	# add language files
	if [ ! -e "/usr/trimui/res/skin/pl.lang" ]; then
		cp "/mnt/SDCARD/trimui/res/lang/"*.lang "/usr/trimui/res/lang/"
		cp "/mnt/SDCARD/trimui/res/lang/"*.short "/usr/trimui/res/lang/"
		cp "/mnt/SDCARD/trimui/res/lang/"*.png "/usr/trimui/res/skin/"
	fi

	# custom shutdown script for "Resume at Boot"
	cp "/mnt/SDCARD/System/usr/trimui/bin/kill_apps.sh" "/usr/trimui/bin/kill_apps.sh"
	chmod a+x "/usr/trimui/bin/kill_apps.sh"

	# fix retroarch path for PortMaster
	cp "/mnt/SDCARD/System/usr/trimui/bin/retroarch" "/usr/bin/retroarch"
	chmod a+x "/usr/bin/retroarch"

	# custom shutdown script, will be called by MainUI
	# cp "/mnt/SDCARD/System/bin/shutdown" "/usr/bin/poweroff"
	# chmod a+x "/usr/bin/poweroff"

	# modifying default theme to impact all other themes (Better game image background)
	# mv "/usr/trimui/res/skin/ic-game-580.png" "/usr/trimui/res/skin/ic-game-580_old.png"
	cp "/mnt/SDCARD/trimui/res/skin/ic-game-580.png" "/usr/trimui/res/skin/ic-game-580.png"

	# modifying FN cpu script (don't force slow cpu, only force high speed when FN is set to ON) (and we set it as default)
	cp /mnt/SDCARD/System/usr/trimui/res/apps/fn_editor/com.trimui.cpuperformance.sh /usr/trimui/apps/fn_editor/com.trimui.cpuperformance.sh

	if [ "$CrossMix_Update" ]; then
		if [ -f /usr/trimui/scene/com.trimui.cpuperformance.sh ]; then
			cp /mnt/SDCARD/System/usr/trimui/res/apps/fn_editor/com.trimui.cpuperformance.sh /usr/trimui/scene/com.trimui.cpuperformance.sh
		fi
	else # in case of fresh install we set the default FN function on CPU Performance  Mode
		cp /mnt/SDCARD/System/usr/trimui/res/apps/fn_editor/com.trimui.cpuperformance.sh /usr/trimui/scene/com.trimui.cpuperformance.sh
	fi

	# fix potential bad asound configuration
		sed -i -e 's/period_size 2048/period_size 1024/' -e 's/period_size 4096/period_size 1024/' -e '/buffer_size 16384/d' "/etc/asound.conf"

	# Apply default CrossMix theme, sound volume, and grid view
	if [ ! "$CrossMix_Update" ]; then
		if [ ! -f /mnt/UDISK/system.json ]; then
			cp /mnt/SDCARD/System/usr/trimui/scripts/MainUI_default_system.json /mnt/UDISK/system.json
		else
			/usr/trimui/bin/systemval theme "/mnt/SDCARD/Themes/CrossMix - OS/"
			/usr/trimui/bin/systemval menustylel1 1
			/usr/trimui/bin/systemval bgmvol 10
		fi
	fi

	# modifying performance mode for Moonlight

	if ! grep -qF "performance" "/usr/trimui/apps/moonlight/launch.sh"; then
		sed -i 's|^\./moonlightui|echo performance > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor\necho 1608000 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq\n\./moonlightui|' /usr/trimui/apps/moonlight/launch.sh
	fi
	# we set the customization flag
	rm "/usr/trimui/fw_mod_done"
	echo $version >/usr/trimui/crossmix-version.txt
	sync

	################ CrossMix-OS SD card Customization ################

	# Sorting Themes Alphabetically
	"/mnt/SDCARD/Apps/SystemTools/Menu/THEME/Sort Themes Alphabetically.sh" -s

	# Game tab by default
	if [ ! "$CrossMix_Update" ]; then
		"/mnt/SDCARD/Apps/SystemTools/Menu/USER INTERFACE##START TAB (value)/Tab Game.sh" -s
	fi

	# Displaying only Emulators with roms
	/mnt/SDCARD/Apps/EmuCleaner/launch.sh -s

	################ Flash boot logo ################
	if [ ! "$CrossMix_Update" ]; then
		CrossMixFWfile="/mnt/SDCARD/trimui/firmwares/MinFwVersion.txt"
		Current_FW_Revision=$(grep 'DISTRIB_DESCRIPTION' /etc/openwrt_release | cut -d '.' -f 3)
		Required_FW_Revision=$(sed -n '2p' "$CrossMixFWfile")

		if ! [ "$Current_FW_Revision" -gt "$Required_FW_Revision" ]; then # on firmware hotfix 9 there is less space than before on /dev/mmcblk0p1 so we avoid to flash the logo
			SOURCE_FILE="/mnt/SDCARD/Apps/BootLogo/Images/- CrossMix-OS.bmp"
			"/mnt/SDCARD/Emus/_BootLogo/launch.sh" "$SOURCE_FILE"
		fi
	fi
fi

######################### CrossMix-OS at each boot #########################

# Apply current led configuration
/mnt/SDCARD/System/etc/led_config.sh &
