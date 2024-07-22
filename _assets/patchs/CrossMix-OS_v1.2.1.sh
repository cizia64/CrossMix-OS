#!/bin/sh

NONE='\033[00m'
RED='\033[01;31m'
GREEN='\033[01;32m'
YELLOW='\033[01;33m'
PURPLE='\033[01;35m'
CYAN='\033[01;36m'
WHITE='\033[01;37m'
BOLD='\033[1m'
UNDERLINE='\033[4m'
BLINK='\x1b[5m'

Current_asound_conf=$(crc32 "/etc/asound.conf" | awk '{print $1}')

if [ "$Current_asound_conf" = "d6a69715" ]; then
	echo -e "${GREEN}Patch not necessary or already applied.${NC}"
	sleep 3
	exit
fi

rm -rf /usr/trimui/res/sound/bgm2.mp3
swapoff -a
rm -rf /swapfile

minspace=$((20 * 1024)) # 20 MB
rootfs_space=$(df / | awk 'NR==2 {print $4}')

if [ "$rootfs_space" -lt "$minspace" ]; then
	echo -ne "${RED}Error: Available space on internal storage is less than 20 MB${NC}\n"
	echo "Free up some space on rootFS / internal storage then try again."
	sleep 6
	exit 1
else
	echo -e "${GREEN}Available space on / is sufficient: ${rootfs_space} KB${NONE}"
fi
sleep 1

GITHUB_REPOSITORY=cizia64/CrossMix-OS
version=$(cat /mnt/SDCARD/System/usr/trimui/crossmix-version.txt)
url="https://raw.githubusercontent.com/$GITHUB_REPOSITORY/main/_assets/patchs/CrossMix-OS_v$version.zip"

urlcmd=$(echo "wget  "$url" -O \"/tmp/CrossMix-OS_v$version.zip\"")
echo $urlcmd >/tmp/rundl.sh
sh /tmp/rundl.sh >/dev/null 2>&1

if [ -f "/tmp/CrossMix-OS_v$version.zip" ]; then
	echo -e "${GREEN}Patch download OK!${NONE}"
	echo "Applying patch..."
	/mnt/SDCARD/System/bin/7zz x -aoa "/tmp/CrossMix-OS_v$version.zip" -o"/mnt/SDCARD"
	sync
	cp "/mnt/SDCARD/System/usr/trimui/etc/asound.conf" "/etc/asound.conf"
	if [ $? -eq 0 ]; then
		echo -e "${GREEN}Patch v$version successful. Rebooting now${NC}"
		rm "/tmp/CrossMix-OS_v$version.zip"
		sleep 6
		if [ -f /mnt/SDCARD/System/bin/shutdown ]; then
			/mnt/SDCARD/System/bin/shutdown -r
		else
			reboot &
		fi
		sleep 30
	else
		echo -ne "${RED}Patch v$version failed.${NC}\n"
	fi
else
	echo -e "${RED}Patch download failed.${NONE}"
fi

sleep 5
