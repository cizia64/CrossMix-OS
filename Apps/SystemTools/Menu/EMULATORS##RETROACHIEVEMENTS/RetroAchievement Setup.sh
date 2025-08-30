#!/bin/sh
export LD_LIBRARY_PATH=/mnt/SDCARD/Apps/TubeExJuk:/mnt/SDCARD/System/lib:/lib64:/usr/trimui/lib:/usr/lib
export PATH="/mnt/SDCARD/System/bin:/mnt/SDCARD/System/usr/trimui/scripts:$PATH"
export HOME="/mnt/SDCARD/RetroArch"
TOOL_DIR=$(dirname "$0")
RA_Config="$HOME/retroarch.cfg"

escape_string() {
	echo -n "$1" | sed 's/\\/\\\\/g; s/"/\\"/g; s/'\''/\\'\''/g; s/ /\\ /g'
}

get_credentials() {
	Username=$(grep "^cheevos_username" "$RA_Config" | sed -n 's/^[^"]*"\(.*\)".*$/\1/p')
	Password=$(grep "^cheevos_password" "$RA_Config" | sed -n 's/^[^"]*"\(.*\)".*$/\1/p')
}

SetAccount() {
	ConfigFile="/mnt/SDCARD/RetroArch/retroarch.cfg"
	Username=$(VirtualKeyboard -i "${TOOL_DIR}/.RAusername.png" -t "$Username" | grep -o '\[VKStart\].*\[VKEnd\]' | sed -e 's/\[VKStart\]//' -e 's/\[VKEnd\]//')
	Password=$(VirtualKeyboard -i "${TOOL_DIR}/.RApassword.png" -p | grep -o '\[VKStart\].*\[VKEnd\]' | sed -e 's/\[VKStart\]//' -e 's/\[VKEnd\]//')
	sed -i "s/^cheevos_username.*/cheevos_username = \"$Username\"/" "$ConfigFile"
	sed -i "s/^cheevos_password.*/cheevos_password = \"$Password\"/" "$ConfigFile"
}

generate_token() {
	mkdir -p /tmp/retroachievements
	cd /tmp/retroachievements || exit 1
	sed -i 's/^cheevos_enable =.*/cheevos_enable = "true"/' "$RA_Config"
	cp "$RA_Config" ./retroarch.cfg
	sed -i 's/^config_save_on_exit.*/config_save_on_exit = "true"/' retroarch.cfg

	$HOME/ra64.trimui -L "$HOME/.retroarch/cores/stella2014_libretro.so" -c "retroarch.cfg" "$(dirname "$0")/.Sheep It Up.zip" &
	sleep 5
	pkill -f ra64.trimui
	sleep 5

	Token=$(grep "^cheevos_token" retroarch.cfg | cut -d '"' -f 2)
}

set_credentials() {

	Username=$(escape_string "$1")
	Token="$2"

	# PPSSPP
	sed -i "s/^AchievementsEnable =.*/AchievementsEnable = True/" /mnt/SDCARD/Emus/PSP/PPSSPP/.config/ppsspp/PSP/SYSTEM/ppsspp.ini
	sed -i "s/^AchievementsUserName =.*/AchievementsUserName = \"$Username\"/" /mnt/SDCARD/Emus/PSP/PPSSPP/.config/ppsspp/PSP/SYSTEM/ppsspp.ini
	echo "$Token" >/mnt/SDCARD/Emus/PSP/PPSSPP/.config/ppsspp/PSP/SYSTEM/ppsspp_retroachievements.dat

	# Flycast
	sed -i "s/^Enabled =.*/Enabled = true/" /mnt/SDCARD/Emus/DC/flycast_v2.4/config/emu.cfg
	sed -i "s/^UserName =.*/UserName = $Username/" /mnt/SDCARD/Emus/DC/flycast_v2.4/config/emu.cfg
	sed -i "s/^Token =.*/Token = $Token/" /mnt/SDCARD/Emus/DC/flycast_v2.4/config/emu.cfg

	Message="$Message ➔ Done.\nRetroAchievements account setuped for RetroArch, PPSSPP and Flycast."
	infoscreen2.sh -fi 0 -p top-left -fb -m "$Message" -fs 14 -k rout B Exit
}

cleanup() {
	rm -rf /tmp/retroachievements
}

### MAIN ###

if ! wget -q --spider retroachievements.org >/dev/null; then
	infoscreen2.sh -fi 0 -p top-left -fb -m "No network connection! Please connect to the internet first." -fs 14 -k rout B Exit
	exit 1
fi

Message="Check Retroarch's RetroAchivement account"
infoscreen2.sh -m "$Message\n" -fs 14 -fi 0 -p top-left -fb -sp &
get_credentials
sleep 0.8
pkill presenter
sleep 0.5

if [ -n "$Username" ]; then
	Message="$Message\nUsername '$Username' already set"
	infoscreen2.sh -fi 0 -p top-left -fb -m "$Message ➔ Overwrite it?" -fs 14 -k rout A Yes -k lout B No

	if [ "$?" -eq 14 ]; then # A has been pressed
		SetAccount
	else
		Message="$Message -> No overwrite\nUse this existing account anyway?"
		infoscreen2.sh -fi 0 -p top-left -fb -m "$Message" -fs 14 -k rout A Yes -k lout B No
		if [ "$?" -eq 11 ]; then
			Message="$Message -> No\nExiting..."
			infoscreen2.sh -fi 0 -p top-left -fb -m "$Message" -fs 14 -ts 1.5
			exit 1
		fi
		Message="$Message -> Yes"
	fi
else

	Message="$Message ➔ Not set."
	infoscreen2.sh -m "$Message" -fs 14 -fi 0 -p top-left -fb &
	sleep 1.5
	pkill presenter
	Message="$Message\nNew account set: $Username"
	SetAccount
fi

while true; do
	Message="$Message\nToken generation, running retroarch few seconds."
	infoscreen2.sh -m "$Message\n" -fs 14 -fi 0 -p top-left -fb -sp &
	get_credentials
	sleep 3
	pkill presenter
	sleep 0.5
	generate_token

	if [ -n "$Token" ]; then
		Message="$Message\nRetroArch token generation successfull!"
		infoscreen2.sh -m "$Message\n" -fs 14 -fi 0 -p top-left -fb -ts 1
		Message="$Message\nApplying to PPSSPP and Flycast"
		infoscreen2.sh -m "$Message\n" -fs 14 -fi 0 -p top-left -fb -ts 1
		set_credentials "$Username" "$Token"
		cleanup
		exit 0
	else
		Message="$Message\nRetroArch token generation failed!\nRestart process ?"
		infoscreen2.sh -fs 14 -fi 0 -p top-left -fb -m "$Message" -k rout A Yes -k lout B No
		if [ "$?" -eq 14 ]; then
			Message="$Message ➔ Yes\nRestarting RetroAchivement setup..."
			SetAccount
		else
			Message="$Message ➔ No\nExiting..."
			infoscreen2.sh -fi 0 -p top-left -fb -m "$Message" -fs 14 -ts 3
			exit 1
		fi

	fi
done
