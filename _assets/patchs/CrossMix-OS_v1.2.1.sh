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

GITHUB_REPOSITORY=cizia64/CrossMix-OS
version=$(cat /mnt/SDCARD/System/usr/trimui/crossmix-version.txt)
url="https://raw.githubusercontent.com/$GITHUB_REPOSITORY/main/_assets/patchs/CrossMix-OS_v$version.zip"


urlcmd=$(echo "wget  "$url" -O \"/tmp/CrossMix-OS_v$version.zip\"")
echo $urlcmd >/tmp/rundl.sh
sh /tmp/rundl.sh  >/dev/null 2>&1

if [ -f "/tmp/CrossMix-OS_v$version.zip" ]; then
	echo -e "${GREEN}Patch download OK!${NONE}"
	echo "Applying patch..."
	/mnt/SDCARD/System/bin/7zz x -aoa "/tmp/CrossMix-OS_v$version.zip" -o"/mnt/SDCARD"
	sync
	cp "/mnt/SDCARD/System/usr/trimui/etc/asound.conf" "/etc/asound.conf"
	if [ $? -eq 0 ]; then
	  echo -e "${GREEN}Patch v$version successful.${NC}"
	  rm "/tmp/CrossMix-OS_v$version.zip"
	else
	  echo -ne "${RED}Patch v$version failed.${NC}\n"
	fi
else
	echo -e "${RED}Patch download failed.${NONE}"
fi

sleep 5
