#!/bin/sh
export PATH="/mnt/SDCARD/System/usr/trimui/scripts/:/mnt/SDCARD/System/bin:/usr/trimui/bin:$PATH"
export LD_LIBRARY_PATH="/mnt/SDCARD/System/lib:/mnt/SDCARD/Apps/PortMaster/PortMaster:/usr/trimui/lib:$LD_LIBRARY_PATH"

NONE='\033[0m'
RED='\033[01;31m'
GREEN='\033[01;32m'
YELLOW='\033[01;33m'
PURPLE='\033[01;35m'
CYAN='\033[01;36m'
WHITE='\033[01;37m'
BOLD='\033[1m'
UNDERLINE='\033[4m'
BLINK='\x1b[5m'

if pgrep "SimpleTerminal" >/dev/null; then
	clear
fi

timestamp=$(date +'%Y%m%d-%Hh%M')

LOG_FILE="/mnt/SDCARD/System/updates/portmaster_fix_$timestamp.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo -e "\n==== PortMaster Fix started at $timestamp ==="

########################################### Internal Storage disk space check ###########################################

echo -e "\n${YELLOW}Checking internal storage space...${NONE}"
echo "----------------------------------"
minspace=$((20 * 1024)) # 20 MB
rootfs_space=$(df / | awk 'NR==2 {print $4}')

if [ "$rootfs_space" -lt "$minspace" ]; then
	# Cleaning root
	for f in /*; do if [ -f "$f" ] && [ ! "$f" == "/device_info_TrimUI_TrimUI Smart Pro.txt" ] && [ ! "$f" == "/rdinit" ] && [ ! "$f" == "/worldmap.dat" ]; then rm $f; fi; done
	rootfs_space=$(df / | awk 'NR==2 {print $4}')
	if [ "$rootfs_space" -lt "$minspace" ]; then
		echo -ne "${RED}Error: Available space on internal storage is less than 20 MB${NONE}\n"
		echo "Free up some space on rootFS / internal storage then try again."
		echo "The easiest way is to flash your firmware again."
		sleep 10
		exit 1
	fi
else
	echo -e "${GREEN}Available space on internal storage is sufficient: ${rootfs_space} KB${NONE}"
fi
sleep 1

########################################### Check internet connection ###########################################

echo -e "\n${YELLOW}Checking internet connection...${NONE}"
echo "-------------------------------"
if /mnt/SDCARD/System/bin/wget -q --spider https://github.com >/dev/null; then
	echo -e "${GREEN}OK${NONE}"
else
	echo -e "${RED}FAIL$\nError: https://github.com not reachable.${NONE}\n!!! Check your wifi connection !!!\n"
	echo -e "It is possible to use this script without Wifi."
	echo -e "However for best results please enable wifi on your device.\n"
	echo -e "Press A to continue. B to quit the fix script."
	button=$(/mnt/SDCARD/System/usr/trimui/scripts/getkey.sh "A B" 2>/dev/null)
	if [ "$button" = "B" ]; then
		echo exiting
		killall -2 SimpleTerminal
	fi
fi

########################################### Check SD card filesystem state ###########################################

echo -e "\n${YELLOW}Checking SD card filesystem integrity...${NONE}"
echo "----------------------------------------"
# check disk integrity
mount_point=$(mount | grep -m 1 '/mnt/SDCARD' | awk '{print $1}')
echo -ne "\n" \
	"Please wait during FAT file system integrity check.\n" \
	"Issues should be fixed automatically.\n" \
	"The process can be long:\n" \
	"about 2 minutes for 128GB SD card\n\n"

/mnt/SDCARD/System/bin/fsck.fat -a $mount_point 2>&1 | awk 'NR > 3'

########################################### Check portmaster fix file integrity ###########################################

echo -e "\n${YELLOW}Checking PortMaster Fix file integrity...${NONE}"
echo "--------------------------------------------"

# check integrity of restore file
PortMaster_FixAchive="/mnt/SDCARD/System/updates/portmaster_fix.7z"
PortMaster_FixAchive_CRC=$(crc32 "$PortMaster_FixAchive" | awk '{print $1}')

if [ "$PortMaster_FixAchive_CRC" = "e8efc05d" ]; then
	echo -e "${GREEN}PortMaster archive is OK.${NONE}"
	sleep 2
	echo "Extracting..."
	/mnt/SDCARD/System/bin/7zz x -aoa "$PortMaster_FixAchive" -o"/mnt/SDCARD"
else
	rm "$PortMaster_FixAchive"
	sync
	echo "PortMaster archive is corrupted."
	echo "Downloading PortMaster archive..."
	url="https://raw.githubusercontent.com/cizia64/CrossMix-OS/refs/heads/main/_assets/ressources/portmaster_fix.7z"
	wget -q -O "$PortMaster_FixAchive" "$url"

	if [ $? -ne 0 ]; then
		echo -e "  \"portmaster_fix.7z\" ${RED}download KO${NC}"
		rm -f "$local_file"
	else
		echo -e "  \"portmaster_fix.7z\" ${GREEN}download OK${NC}"
		echo "Extracting..."
		/mnt/SDCARD/System/bin/7zz x -aoa "$PortMaster_FixAchive" -o"/mnt/SDCARD"
		if [ $? -eq 0 ]; then
			echo -e "${GREEN}PortMaster extraction successful.${NONE}"
			sleep 3
		else
			echo -ne "${RED}PortMaster extraction failed.${NONE}\n"
		fi
	fi

fi

sync

########################################### Check python file integrity ###########################################

echo -e "\n${YELLOW}Checking Python archive integrity...${NONE}"
echo "------------------------------------"

# check integrity of python file
Python_Archive="/mnt/SDCARD/System/updates/update_001/python.zip"
Python_Archive_CRC=$(crc32 "$Python_Archive" | awk '{print $1}')

if [ "$Python_Archive_CRC" = "ffbe30be" ]; then
	echo -e "${GREEN}Python archive is OK.${NONE}"
	sleep 3
else
	echo -e "${RED}Python archive integrity is KO.${NONE}"
	rm "$Python_Archive"
	sync
	echo "Downloading Python archive..."
	url="https://github.com/kloptops/TRIMUI_EX/raw/refs/heads/main/System/updates/update_001/python.zip"

	wget -q -O "$Python_Archive" "$url"

	if [ $? -ne 0 ]; then
		echo -e "  \"Python archive\" ${RED}download KO${NC}"
		rm -f "$local_file"
	else
		echo -e "  \"Python archive\" ${GREEN}download OK${NC}"
	fi

fi

########################################### Run standard PortMaster installation ###########################################

echo -e "\n${YELLOW}Running standard PortMaster installation...${NONE}"
echo "-------------------------------------------"

#   ex_init.sh             -> ex_config.sh, fix mac, ex_update.sh, launch dropbear & sftpgo
#   │
#   ├─►ex_config.sh        -> env initialization
#   └─►ex_update.sh        -> extract TRIMUI_EX.zip, run update scripts, extract trimui.portmaster.zip
#       │
#       ├►update_001.sh    -> ssl certs, new busybox, symbolic links, python extraction
#       ├►update_002.sh    -> sftp-server
#       └►update_00X.sh    -> python extraction (again)

# launch restore process

rm "/etc/ex_update/001"
rm "/etc/ex_update/002"
rm "/etc/ex_update/00X"

sleep 3

source /mnt/SDCARD/System/etc/ex_config
/mnt/SDCARD/System/bin/ex_update.sh

########################################### Reset & Backup PortMaster configuration files ###########################################

echo -e "\n${YELLOW}Backing up PortMaster configuration files...${NONE}"
echo "--------------------------------------------"
# backup config file
mv /mnt/SDCARD/Apps/PortMaster/PortMaster/config /mnt/SDCARD/Apps/PortMaster/PortMaster/config_$timestamp
sync

########################################### Check runtime files integrity ###########################################

echo -e "\n${YELLOW}Starting runtimes check script...${NONE}"
echo "---------------------------------"
# checksum of each runtime
/mnt/SDCARD/System/usr/trimui/scripts/portmaster_runtimes_check.sh # will create default config files too
sync

################################################################################### EXIT ##########################################################################################################

echo -e "\n${YELLOW}PortMaster fix finished.${NONE}"
echo "------------------------"

if pgrep "SimpleTerminal" >/dev/null; then
	echo -e "${PURPLE}Exiting in 10 seconds...${NONE}\n"
	echo "Logs will be avaible in"
	echo "/SDCARD/System/updates/portmaster_fix_$timestamp.log"
	sleep 15
	echo "exiting"
	killall -2 SimpleTerminal
fi
