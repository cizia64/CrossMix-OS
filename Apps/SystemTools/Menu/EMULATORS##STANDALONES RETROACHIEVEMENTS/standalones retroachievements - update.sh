#!/usr/bin/env sh

export PATH="$PATH:/mnt/SDCARD/System/usr/trimui/scripts"
export HOME="/mnt/SDCARD/RetroArch"

button=$(infoscreen.sh -m "You will login to retroachievements with ppsspp standalone.\n\
This require that you have already setup your username and password in retroarch\n\
Press A to continue, B to cancel operation." -k "A B" -fs 30)

if [ "$button" = "B" ]; then
    exit 0
fi

if ! ping -q -c 1 -W 1 retroachievements.org > /dev/null; then
    infoscreen.sh -m "No network connection! Please connect to the internet first." -k "A B START MENU" -fs 30
    exit 1
fi

mkdir -p /mnt/SDCARD/tmp
cd /mnt/SDCARD/tmp


ConfigFile="./retroarch.cfg"

cp /mnt/SDCARD/RetroArch/retroarch.cfg "$ConfigFile"

Username=$(grep "^cheevos_username" "$ConfigFile"| cut -d '"' -f 2)
Password=$(grep "^cheevos_password" "$ConfigFile" | cut -d '"' -f 2)

if [ -z "$Username" ] || [ -z "$Password" ]; then
	infoscreen.sh -m "Username or password not found! Please set them in RetroArch app first." -k "A B START MENU" -fs 30
	exit 1
fi

sed -i 's/^config_save_on_exit.*/config_save_on_exit = "true"/' "$ConfigFile"

infoscreen.sh -m "A game will start and close to generate your token, please wait. Press A to continue." -k "A B START MENU" -fs 15
$HOME/ra64.trimui -L "$HOME/.retroarch/cores/mgba_libretro.so" -c "$ConfigFile" "/mnt/SDCARD/Best/Free Games Collection/Roms/GBA/SpaceTwins.zip" &
sleep 5
pkill -f ra64.trimui
sleep 5

Token=$(grep "^cheevos_token" "$ConfigFile"| cut -d '"' -f 2)

if [ -z "$Token" ]; then
	infoscreen.sh -m "Failed to get cheevos token! Please check your username and password." -k "A B START MENU" -fs 30
	exit 1
fi

# PPSSPP 1.17.1
sed -i "s/^AchievementsUserName =.*/AchievementsUserName = \"$Username\"/" /mnt/SDCARD/Emus/PSP/PPSSPP_1.17.1/.config/ppsspp/PSP/SYSTEM/ppsspp.ini
echo "$Token" >/mnt/SDCARD/Emus/PSP/PPSSPP_1.17.1/.config/ppsspp/PSP/SYSTEM/ppsspp_retroachievements.dat

rm -rf .retroarch
rm -f content_*
rm -f $ConfigFile

infoscreen.sh -m "RetroAchievements credentials set successfully for PPSSPP!" -k "A B START MENU" -fs 30

exit 0
