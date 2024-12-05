#!/bin/sh

UDISK_TIRMUI_DIR=/mnt/UDISK/trimui_dir
SDCARD_TRIMUI_DIR=/mnt/SDCARD/trimui
export LD_LIBRARY_PATH=/usr/trimui/lib:${SDCARD_TRIMUI_DIR}/lib

SWAP_AB_enabled=$(/mnt/SDCARD/System/bin/jq -r '.["SWAP A B"]' "/mnt/SDCARD/System/etc/crossmix.json")
if [ "$SWAP_AB_enabled" -eq 1 ]; then
  touch /var/trimui_inputd/swap_ab
fi
rm -f /var/trimui_inputd/ra_hotkey

runifnecessary() {
	a=$(pgrep "$1")
	if [ "$a" = "" ]; then
		$2 &
	fi
}

if [ -f "/mnt/SDCARD/trimui/app/cmd_to_run.sh" ]; then

	resume_at_boot=$(/mnt/SDCARD/System/bin/jq -r '.["RESUME AT BOOT"]' "/mnt/SDCARD/System/etc/crossmix.json")
	if [ "$resume_at_boot" -eq 0 ]; then
		rm /mnt/SDCARD/trimui/app/cmd_to_run.sh
		echo "The value of 'RESUME AT BOOT' is 0."
		exit 1
	fi

	# set wifi
	max_wait_ip=20
	wifi_value=$(/usr/trimui/bin/systemval wifi)
	if [ "$wifi_value" -eq 1 ]; then
		udhcpc -i wlan0 &
		while true; do
			ip=$(ifconfig wlan0 | grep 'inet addr:' | cut -d: -f2 | cut -d' ' -f1)
			if [ -z "$ip" ]; then
				attempts=$((attempts + 1))
				echo "WifiInit: Waiting for IP address since $attempts seconds"
				if [ $attempts -ge $max_wait_ip ]; then
					echo "WifiInit: Could not aquire an IP address"
					ret_val=1
					got_ip=0
					break
				fi
			else
				echo "WifiInit: IP address aquired: $ip"
				got_ip=1
				break
			fi
			sleep 0.5
		done

	fi

	mkdir -p $UDISK_TIRMUI_DIR
	mounted=$(mount | grep $UDISK_TIRMUI_DIR)
	if [ "$mounted" == "" ]; then
		mount -o loop $UPDATE_DEST $UDISK_TIRMUI_DIR
		if [ $? -eq 0 ]; then
			echo "new img mounted" >>/tmp/imgrun.log
			udiskOK=1
		fi
	else
		echo "img mounted" >>/tmp/imgrun.log
		udiskOK=1
	fi

	cd /usr/trimui/bin/
	runifnecessary "keymon" /usr/trimui/bin/keymon
	runifnecessary "inputd" /usr/trimui/bin/trimui_inputd
	runifnecessary "scened" /usr/trimui/bin/trimui_scened
	runifnecessary "trimui_btmanager" /usr/trimui/bin/trimui_btmanager

	#########################################
	# Set brightness
	brightness_value=$(/usr/trimui/bin/systemval brightness)

	min_brightness=0
	max_brightness=10
	min_LCD_Value=10
	max_LCD_Value=250

	LCD_Value=$((min_LCD_Value + (brightness_value - min_brightness) * (max_LCD_Value - min_LCD_Value) / (max_brightness - min_brightness)))

	echo "LCD brightness value : $LCD_Value"

	cd /sys/kernel/debug/dispdbg
	echo lcd0 >name
	echo setbl >command
	echo $LCD_Value >param
	echo 1 >start

	#########################################
	tinymix set 9 1
	tinymix set 1 0
	# Restore sound volume
	amix_min=40
	amix_max=1
	soundlvl_max=20
	soundlvl_value=$(/usr/trimui/bin/systemval vol)
	if [ "$soundlvl_value" -eq 0 ]; then
		volume=63
	else
		volume=$((amix_min - ((soundlvl_value * amix_min) / soundlvl_max)))
	fi
	echo "amixer digital volume set to $volume"
	amixer -c 0 sset "digital volume" $volume

	#########################################

	echo "Lets run"

	sleep 0.3 # delay necessary for input initialization
	/mnt/SDCARD/System/usr/trimui/scripts/button_state.sh MENU
	exit_code=$?
	if [ $exit_code -eq 10 ]; then # we don't resume if menu is pressed during boot
		echo "=== Button MENU pressed ==="
		rm /mnt/SDCARD/trimui/app/cmd_to_run.sh
		sync
		# 3 fast blue blinking
		echo 1 >/sys/class/led_anim/effect_enable
		echo "0000FF" >/sys/class/led_anim/effect_rgb_hex_lr
		echo 3 >/sys/class/led_anim/effect_cycles_lr
		echo 200 >/sys/class/led_anim/effect_duration_lr
		echo 5 >/sys/class/led_anim/effect_lr
		exit
	fi

	cp /mnt/SDCARD/trimui/app/cmd_to_run.sh /tmp/cmd_to_run.sh
	/mnt/SDCARD/trimui/app/cmd_to_run.sh
	rm /mnt/SDCARD/trimui/app/cmd_to_run.sh
	sync
	exit 1
else

	exit 1
fi
