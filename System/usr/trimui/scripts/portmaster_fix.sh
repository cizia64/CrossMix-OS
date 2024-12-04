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

########################################### Functions ###########################################


exit_simple_terminal() {
    if pgrep "SimpleTerminal" >/dev/null; then
        echo -e "${PURPLE}Exiting in 10 seconds...${NONE}\n"
        echo "Logs will be available in"
        echo "/SDCARD/System/updates/portmaster_fix_$timestamp.log"
        sleep 15
        echo "exiting"
        killall -2 SimpleTerminal
    fi
}

download_file() {
    local url="$1"
    local output="$2"

    # echo -e "Downloading from: $url..."
    wget -q "$url" -O "$output"
    if [ $? -eq 0 ] && [ -s "$output" ]; then
        echo -e "$(basename "$output") ${GREEN}Download OK${NONE}"
        return 0
    else
        echo -e "$(basename "$output") ${RED}Download KO${NONE}"
        rm -f "$output"
        return 1
    fi
}

verify_md5() {
    local filePath="$1"
    local fileName=$(basename "$filePath")
    local md5_file="$2"
    $(basename "$file")

    echo -e "${YELLOW}Checking integrity of $fileName...${NONE}"
    if [ -f "$md5_file" ]; then
        md5sum -c "$md5_file" >/dev/null 2>&1
        if [ $? -eq 0 ]; then
            echo -e "$fileName ${GREEN}integrity OK.${NONE}"
            return 0
        else
            echo -e "$fileName ${RED}integrity KO.${NONE}"
            return 1
        fi
    else
        echo -e "${RED}MD5 file not found: $md5_file${NONE}"
        return 1
    fi
}

extract_archive() {
    local archive_path="$1"
    local archive_filename=$(basename "$archive_path")
    local output_dir="$2"

    echo -e "${YELLOW}Extracting $archive_filename to $output_dir...${NONE}"
    /mnt/SDCARD/System/bin/7zz x -aoa "$archive_path" -o"$output_dir"
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Extraction of $archive_filename successful.${NONE}"
        sleep 3
    else
        echo -e "${RED}Extraction of $archive_filename failed.${NONE}"
    fi
}

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
        exit_simple_terminal
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
        exit_simple_terminal
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
rec_dir="/mnt/SDCARD/rec_files"
mkdir -p "$rec_dir"
mv /mnt/SDCARD/FSCK*.REC "$rec_dir" 2>/dev/null

cat > "$rec_dir/_description.txt" <<EOL
The files with the extension .REC are recovery files generated by the fsck.fat tool during a file system integrity check.
These files are created when the tool encounters potential issues with the file system. 
They may contain data that was recovered or repaired. In general, these files can be ignored if no issues are noticed with the system.
However, they may also contain partial or deleted data that may not be fully usable.
You can safely delete them if you're sure the file system is working properly.
EOL

########################################### Check portmaster fix file integrity ###########################################

# Main script
echo -e "\n${YELLOW}Checking PortMaster Fix file integrity...${NONE}"
echo "-----------------------------------------"

# Variables
PM_FixArchive="/mnt/SDCARD/System/updates/portmaster_fix.7z"
PM_FixArchive_MD5="/mnt/SDCARD/System/updates/portmaster_fix.7z.md5"
PM_FixArchive_URL="https://raw.githubusercontent.com/cizia64/CrossMix-OS/refs/heads/main/_assets/resources/portmaster_fix.7z"
PM_FixArchive_MD5_URL="https://raw.githubusercontent.com/cizia64/CrossMix-OS/refs/heads/main/_assets/resources/portmaster_fix.7z.md5"
TEMP_FILE="/tmp/portmaster_fix.7z.md5"

# Step 1: Download the remote MD5 file
echo -e "\n${YELLOW}Updating md5 checksum file...${NONE}"
if ! download_file "$PM_FixArchive_MD5_URL" "$TEMP_FILE"; then
    echo "Using local MD5 file copy instead."
else
    mv "$TEMP_FILE" "$PM_FixArchive_MD5"
fi

# Step 2: Verify the integrity of the target file
if verify_md5 "$PM_FixArchive" "$PM_FixArchive_MD5"; then
    extract_archive "$PM_FixArchive" "/mnt/SDCARD"
else
    echo -e "${RED}PortMaster archive is corrupted.${NONE}"
    echo -e "Attempting to download a fresh copy..."
    if download_file "$PM_FixArchive_URL" "$PM_FixArchive"; then
        if verify_md5 "$PM_FixArchive" "$PM_FixArchive_MD5"; then
            extract_archive "$PM_FixArchive" "/mnt/SDCARD"
        else
            echo -e "${RED}Downloaded archive is also corrupted. Exiting.${NONE}"
            exit_simple_terminal
        fi
    else
        echo -e "${RED}Failed to download PortMaster archive.${NONE}"
        exit_simple_terminal
    fi
fi

sync

########################################### Check python file integrity ###########################################

echo -e "\n${YELLOW}Checking Python archive integrity...${NONE}"
echo "------------------------------------"

# Variables
Python_Archive="/mnt/SDCARD/System/updates/update_001/python.zip"
Python_Archive_MD5="/mnt/SDCARD/System/updates/update_001/python.zip.md5"
Python_Archive_URL="https://raw.githubusercontent.com/cizia64/CrossMix-OS/refs/heads/main/_assets/resources/python.zip"
Python_Archive_MD5_URL="https://raw.githubusercontent.com/cizia64/CrossMix-OS/refs/heads/main/_assets/resources/python.zip.md5"
TEMP_FILE="/tmp/python.zip.md5"

# Step 1: Download the remote MD5 file
echo -e "\n${YELLOW}Updating md5 checksum file...${NONE}"
if ! download_file "$Python_Archive_URL" "$TEMP_FILE"; then
    echo "Using local MD5 file copy instead."
else
    mv "$TEMP_FILE" "$Python_Archive_MD5"
fi

# Step 2: Verify the integrity of the target file
if ! verify_md5 "$Python_Archive" "$Python_Archive_MD5"; then
    echo -e "${RED}Python archive is corrupted. Attempting to download a fresh copy...${NONE}"
    if download_file "$Python_Archive_URL" "$Python_Archive"; then
        if ! verify_md5 "$Python_Archive" "$Python_Archive_MD5"; then
            echo -e "${RED}Downloaded archive is also corrupted. Exiting.${NONE}"
            exit_simple_terminal
        fi
    else
        echo -e "${RED}Failed to download Python archive.${NONE}"
        exit_simple_terminal
    fi
fi

sync

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

exit_simple_terminal
