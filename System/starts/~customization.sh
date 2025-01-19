#!/bin/sh
export LD_LIBRARY_PATH="/mnt/SDCARD/System/lib:/usr/trimui/lib:$LD_LIBRARY_PATH"
system_json="/mnt/UDISK/system.json"
Current_Theme=$(/usr/trimui/bin/systemval theme)
Current_bg="$Current_Theme/skin/bg.png"
if [ ! -f "$Current_bg" ]; then
	Current_bg="/mnt/SDCARD/trimui/res/skin/transparent.png"
fi

read -r current_device </etc/trimui_device.txt
################ CrossMix-OS Version Splashscreen ################

read -r version </mnt/SDCARD/System/usr/trimui/crossmix-version.txt
/mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -i "$Current_bg" -m "CrossMix OS v$version"

################ CrossMix-OS internal storage Customization ################
read -r FW_patched_version </usr/trimui/crossmix-version.txt

if [ "$version" != "$FW_patched_version" ]; then

	if [ -f "/usr/trimui/crossmix-version.txt" ]; then
		CrossMix_Update=1
	else
		CrossMix_Update=0
	fi

	Current_FW_Revision=$(grep 'DISTRIB_DESCRIPTION' /etc/openwrt_release | cut -d '.' -f 3)

	/mnt/SDCARD/System/usr/trimui/scripts/inputd_switcher.sh
	cp /mnt/SDCARD/System/resources/preload.sh /usr/trimui/bin/preload.sh

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

	# USB Storage app update
	rm "/usr/trimui/apps/usb_storage/"*.png
	cp "/mnt/SDCARD/System/resources/usb_storage/"* "/usr/trimui/apps/usb_storage/"

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

	if [ "$CrossMix_Update" = "1" ]; then
		if [ -f /usr/trimui/scene/com.trimui.cpuperformance.sh ]; then
			cp /mnt/SDCARD/System/usr/trimui/res/apps/fn_editor/com.trimui.cpuperformance.sh /usr/trimui/scene/com.trimui.cpuperformance.sh
		fi
	else # in case of fresh install we set the default FN function on CPU Performance  Mode
		cp /mnt/SDCARD/System/usr/trimui/res/apps/fn_editor/com.trimui.cpuperformance.sh /usr/trimui/scene/com.trimui.cpuperformance.sh
	fi

	# fix potential bad asound configuration
	sed -i -e 's/period_size 2048/period_size 1024/' -e 's/period_size 4096/period_size 1024/' -e '/buffer_size 16384/d' "/etc/asound.conf"

	# Apply default CrossMix theme, sound volume, and grid view
	if [ "$CrossMix_Update" = "0" ]; then
		if [ ! -f /mnt/UDISK/system.json ]; then
			cp /mnt/SDCARD/System/usr/trimui/scripts/MainUI_default_system.json /mnt/UDISK/system.json
		else
			/usr/trimui/bin/systemval theme "/mnt/SDCARD/Themes/CrossMix - OS/"
			/usr/trimui/bin/systemval menustylel1 1
			/usr/trimui/bin/systemval bgmvol 10
		fi
	fi

	if [ "$Current_Theme" = "../res/" ]; then
		/usr/trimui/bin/systemval theme "/mnt/SDCARD/Themes/CrossMix - OS/"
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
	if [ "$CrossMix_Update" = "0" ]; then
		"/mnt/SDCARD/Apps/SystemTools/Menu/USER INTERFACE##START TAB (value)/Tab Game.sh" -s
	fi

	# Displaying only Emulators with roms
	/mnt/SDCARD/Apps/EmuCleaner/launch.sh -s

	################ Flash boot logo ################
	if [ "$CrossMix_Update" = "0" ]; then
		CrossMixFWfile="/mnt/SDCARD/trimui/firmwares/MinFwVersion.txt"
		Current_FW_Revision=$(grep 'DISTRIB_DESCRIPTION' /etc/openwrt_release | cut -d '.' -f 3)
		Required_FW_Revision=$(sed -n '2p' "$CrossMixFWfile")

		if ! [ "$Current_FW_Revision" -gt "$Required_FW_Revision" ]; then # on firmware hotfix 9 there is less space than before on /dev/mmcblk0p1 so we avoid to flash the logo
			SOURCE_FILE="/mnt/SDCARD/Apps/BootLogo/Images/- CrossMix-OS.bmp"
			"/mnt/SDCARD/Emus/_BootLogo/launch.sh" "$SOURCE_FILE"
		fi
	fi
fi

######################### Device Type customization #########################

if [ -f "/tmp/device_changed" ]; then

	read -r last_device </tmp/device_changed
	/mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -i "$Current_bg" -m "Switching to $current_device device. "

	# manage different RA versions
	cp "/mnt/SDCARD/RetroArch/ra64.trimui_$current_device" /mnt/SDCARD/RetroArch/ra64.trimui

    #Change mupen64plus standalone resolution
    n64_conf=/mnt/SDCARD/Emus/N64/mupen64plus/mupen64plus.cfg
    if [ "$current_device" = "brick" ]; then
        sed -i 's/^ScreenWidth =.*$/ScreenWidth = 1024' $n64_conf
        sed -i 's/^ScreenHeight =.*$/ScreenHeight = 768' $n64_conf
    else
        sed -i 's/^ScreenWidth =.*$/ScreenWidth = 1280' $n64_conf
        sed -i 's/^ScreenHeight =.*$/ScreenHeight = 720' $n64_conf
    fi

    /mnt/SDCARD/System/usr/trimui/scripts/inputd_switcher.sh
    /mnt/SDCARD/System/usr/trimui/scripts/starttab_switcher.sh
    /mnt/SDCARD/System/usr/trimui/scripts/overlays_switcher.sh


	# manage theme differences
	themes_dir="/mnt/SDCARD/Themes"

	for theme_folder in "$themes_dir"/*/; do
			themePath="$theme_folder/skin"
			last_device_themePath="$themePath/$last_device"
			current_device_themePath="$themePath/$current_device"

			mkdir -p "$last_device_themePath"
			mkdir -p "$current_device_themePath"
            
            # Save names of images to apply
            cd "$current_device_themePath"
            new_files=$(echo *.png)

            # backup last device images
            cd "$themePath"
            mv $new_files "$last_device_themePath"

            # apply current devices images
            cd "$current_device_themePath"
            mv $new_files "$themePath"

			echo "Copied skin contents from $current_device_themePath to $themePath"
	done
	sync
fi

######################### CrossMix-OS at each boot #########################

# Apply current led configuration
/mnt/SDCARD/System/etc/led_config.sh &

hostname=$(echo "$current_device" | tr 'a-z' 'A-Z')
