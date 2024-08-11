#!/usr/bin/env sh

############################################################################################################

export PATH="$PATH:/mnt/SDCARD/System/usr/trimui/scripts"
export HOME="/mnt/SDCARD/RetroArch"
export TOOL_DIR="/mnt/SDCARD/Apps/SystemTools/Menu/EMULATORS##STANDALONES RETROACHIEVEMENTS/"
ConfigFile="/mnt/SDCARD/RetroArch/retroarch.cfg"

############################################################################################################
#### Functions ####

connectRetroarch() {

	infoscreen.sh -m "Terminal will open to set your credentials. Keybinds: Y-Keyboard; L-Shift; Start-Validate; Menu-Exit" -k "A B START MENU" -fs 22

	pipe=/tmp/fifo
	mkfifo "$pipe"
	(
		cat <<'EOF'
#!/usr/bin/env sh

escape_string() {
    echo -n "$1" | sed 's/\\/\\\\/g; s/"/\\"/g; s/'\''/\\'\''/g; s/ /\\ /g'
}

ConfigFile="/mnt/SDCARD/RetroArch/retroarch.cfg"

echo "Please enter your RetroAchievements username:"
read -r tmp
Username=$(escape_string "$tmp")
sed -i "s/^cheevos_username.*/cheevos_username = \"$Username\"/" "$ConfigFile"
echo "Please enter your RetroAchievements password:"
read -r tmp
Password=$(escape_string "$tmp")
sed -i "s/^cheevos_password.*/cheevos_password = \"$Password\"/" "$ConfigFile"
exit 0
EOF
	) >"$pipe" &

	/mnt/SDCARD/Apps/Terminal/SimpleTerminal -e "sh $pipe; rm -f $pipe" &
	while [ -e "$pipe" ]; do sleep 1; done
	pkill SimpleTerminal

}

############################################################################################################

infoscreen.sh -m "STEP 1: Verification of RetroArch settings" -k "A B START MENU" -fs 22

Username=$(grep "^cheevos_username" "$ConfigFile" | cut -d '"' -f 2)
Password=$(grep "^cheevos_password" "$ConfigFile" | cut -d '"' -f 2)

# Allow user to change credentials
if [ -n "$Username" ]; then

	button=$(
		infoscreen.sh -m "Username $Username is already set. Overwrite it? A: Yes; B: No" -k "A B" -fs 22
	)
	if [ "$button" = "A" ]; then
		connectRetroarch
	fi
fi
Username=$(grep "^cheevos_username" "$ConfigFile" | cut -d '"' -f 2)
Password=$(grep "^cheevos_password" "$ConfigFile" | cut -d '"' -f 2)
# Check if credentials are set
if [ -z "$Username" ] || [ -z "$Password" ]; then
	button=$(infoscreen.sh -m "RetroArch is not connected. Connect? A: Yes; B: No" -k "A B" -fs 22)
	if [ "$button" = "A" ]; then
		connectRetroarch
	else
		exit 0
	fi
fi
Username=$(grep "^cheevos_username" "$ConfigFile" | cut -d '"' -f 2)
Password=$(grep "^cheevos_password" "$ConfigFile" | cut -d '"' -f 2)

############################################################################################################

infoscreen.sh -m "STEP 2: Token generation..." -k "A B START MENU" -fs 22

mkdir -p /mnt/SDCARD/tmp
cd /mnt/SDCARD/tmp

sed -i 's/^cheevos_enable =.*/cheevos_enable = "true"/' "$ConfigFile"
cp $ConfigFile .
ConfigFile="./retroarch.cfg"

if ! ping -q -c 1 -W 1 retroachievements.org >/dev/null; then
	infoscreen.sh -m "No network connection! Please connect to the internet first." -k "A B START MENU" -fs 22
	exit 1
fi

sed -i 's/^config_save_on_exit.*/config_save_on_exit = "true"/' "$ConfigFile"

infoscreen.sh -m "A game will start and close to generate your token, please wait. Press A to continue." -k "A B START MENU" -fs 22
$HOME/ra64.trimui -L "$HOME/.retroarch/cores/mgba_libretro.so" -c "$ConfigFile" "/mnt/SDCARD/Best/Free Games Collection/Roms/GBA/SpaceTwins.zip" &
sleep 5
pkill -f ra64.trimui
sleep 5

Token=$(grep "^cheevos_token" "$ConfigFile" | cut -d '"' -f 2)

if [ -z "$Token" ]; then
	infoscreen.sh -m "Failed to get cheevos token! Restart the script to change credentials." -k "A B START MENU" -fs 22
	exit 1
fi

############################################################################################################
### Apply credentials to all emulators

# PPSSPP 1.17.1
sed -i "s/^AchievementsEnable =.*/AchievementsEnable = True/" /mnt/SDCARD/Emus/PSP/PPSSPP_1.17.1/.config/ppsspp/PSP/SYSTEM/ppsspp.ini
sed -i "s/^AchievementsUserName =.*/AchievementsUserName = \"$Username\"/" /mnt/SDCARD/Emus/PSP/PPSSPP_1.17.1/.config/ppsspp/PSP/SYSTEM/ppsspp.ini
echo "$Token" >/mnt/SDCARD/Emus/PSP/PPSSPP_1.17.1/.config/ppsspp/PSP/SYSTEM/ppsspp_retroachievements.dat

# Flycast
sed -i "s/^Enabled =.*/Enabled = true/" /mnt/SDCARD/Emus/DC/flycast/config/emu.cfg
sed -i "s/^UserName =.*/UserName = $Username/" /mnt/SDCARD/Emus/DC/flycast/config/emu.cfg
sed -i "s/^Token =.*/Token = $Token/" /mnt/SDCARD/Emus/DC/flycast/config/emu.cfg

rm -rf .retroarch
rm -f content_*
rm -f retroarch.cfg

infoscreen.sh -m "RetroAchievements connected and enabled in RA, PPSSPP and Flycast." -k "A B START MENU" -fs 22

exit 0
