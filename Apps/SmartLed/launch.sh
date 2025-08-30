#!/bin/sh
export PATH="/mnt/SDCARD/System/usr/trimui/scripts/:/mnt/SDCARD/System/bin:${PATH:+:$PATH}"
export LD_LIBRARY_PATH="/mnt/SDCARD/System/lib:/usr/trimui/lib:$LD_LIBRARY_PATH"

cd $(dirname "$0")

#!/bin/sh

/mnt/SDCARD/System/usr/trimui/scripts/button_state.sh Y
if [ $? -eq 10 ]; then
	CHOICE=$(/mnt/SDCARD/System/bin/selector -fs 120 -c \
		"Stop SmartLed" \
		"----------------------------" \
		"Enable SmartLed at boot" \
		"Disable SmartLed at boot")

	CHOICE=$(printf '%s\n' "$CHOICE" | sed 's/^.*: //')

	if [ "$CHOICE" = "Stop SmartLed" ]; then
		killall smartledd

	elif [ "$CHOICE" = "Enable SmartLed at boot" ]; then
		sh "/mnt/SDCARD/Apps/SystemTools/Menu/CONTROLS##SMARTLED (state)/SmartLed - enable.sh"
		if ! pgrep -f "smartledd" >/dev/null; then
			./smartledd &
		fi
	elif [ "$CHOICE" = "Disable SmartLed at boot" ]; then
		sh "/mnt/SDCARD/Apps/SystemTools/Menu/CONTROLS##SMARTLED (state)/SmartLed - disable.sh"
	fi
	exit
fi

# Check if deamon is running
if pgrep -f "smartledd" >/dev/null; then
	echo "smartledd is already running"
	killall smartledd
else

	# check if SmartLed is set to automatic start
	SmartLed_enabled=$(/mnt/SDCARD/System/bin/jq -r '.["SMARTLED"]' "/mnt/SDCARD/System/etc/crossmix.json")
	echo "SmartLed_enabled $SmartLed_enabled"
	if ! [ "$SmartLed_enabled" -eq 1 ]; then
		SmartLed_choice=$(/mnt/SDCARD/System/bin/presenter --file /mnt/SDCARD/System/resources/SmartLed_daemon_choice.json --confirm-button A --no-wrap)
		if [ "$SmartLed_choice" = "2" ]; then
			json_file="/mnt/SDCARD/System/etc/crossmix.json"
			jq '. += {"SMARTLED": 1}' "$json_file" >"/tmp/json_file.tmp" && mv "/tmp/json_file.tmp" "$json_file"
			# we modify the DB entries to reflect the current state
			mainui_state_update.sh "SMARTLED" "enabled"

		fi

	fi
fi

./smartledd &

# daemon will refresh instantly if the configuration file is modified
touch /tmp/led_deamon_live

./smartled-ui

rm /tmp/led_deamon_live

# allow other programs to modify led states if led_daemon is set to Nothing
chmod a+w /sys/class/led_anim/*
