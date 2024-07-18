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
	exit
fi

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
		sleep 5
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
