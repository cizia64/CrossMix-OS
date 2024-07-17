#!/bin/sh

# Colors
# RED='\033[1;31m'
# GREEN='\033[1;32m'
# YELLOW='\033[1;33m'
# BLUE='\033[1;34m'
# NC='\033[0m' # No Color

export PATH="/mnt/SDCARD/System/bin:/mnt/SDCARD/System/usr/trimui/scripts:$PATH"
export LD_LIBRARY_PATH="/mnt/SDCARD/System/lib:/usr/trimui/lib:$LD_LIBRARY_PATH"

echo performance >/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
echo 1800000 >/sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq

# Find the update file
UPDATE_FILE=$(find /mnt/SDCARD -maxdepth 1 -name "CrossMix-OS_v*.zip" -print -quit)

initial_version=$(cat /mnt/SDCARD/System/usr/trimui/crossmix-version.txt)
if [ -z "$initial_version" ]; then
  initial_version="x"
fi
update_version=$(echo "$UPDATE_FILE" | awk -F'_v|\.zip' '{print $2}')

# infoscreen.sh -m "test OK." -t 1
cp /mnt/SDCARD/System/bin/7zz /tmp
rm -rf "/mnt/SDCARD/System Volume Information"
echo 1 >/tmp/stay_awake

# Create backup directory
BCK_DIR="/mnt/SDCARD/_Updates/Backup_CrossMix_v$initial_version"
timestamp=$(date +'%Y%m%d-%Hh%M')

if [ -d "$BCK_DIR" ]; then
  BCK_DIR="${BCK_DIR}_$timestamp"
fi
mkdir -p "$BCK_DIR"
sync

restore_files() {
    NAME="$1"
    SRC_DIR="$2"
    DEST_DIR="$3"
    FILE_PATTERN="$4"

    if [ -z "$FILE_PATTERN" ]; then
        FILE_PATTERN="*"
    fi
        echo "------------------------------------------------------------------------------------"
    if [ -n "$(find "$SRC_DIR" -mindepth 1 -name "$FILE_PATTERN" -print -quit 2>/dev/null)" ]; then
		echo -e "$NAME: restoring files...\n"
        mkdir -p "$DEST_DIR"
        /mnt/SDCARD/System/bin/rsync --stats -av --include="*/" --include="$FILE_PATTERN" --exclude="*" "$SRC_DIR/" "$DEST_DIR/"
        sync
    else
        echo "$NAME: No files to restore."
    fi
}


LOG_FILE="/mnt/SDCARD/_Updates/CrossMix_v${update_version}_${timestamp}.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "=========================================================================================="
echo "       ==============  Updating CrossMix-OS v$initial_version to v$update_version  =============="

check_available_space() {
  echo "=========================================================================================="
  echo "       ==============  Checking available space on the SD Card  =============="
  # Available space in MB
  mount_point=$(mount | grep -m 1 '/mnt/SDCARD' | awk '{print $1}')
  available_space=$(df -m $mount_point | awk 'NR==2{print $4}')
  echo "Available space: $available_space MB"
  # Check available space
  if [ "$available_space" -lt "4000" ]; then
    echo -e "${RED}Available space is insufficient on SD card${NC}\n"
    echo "CrossMix-OS update requires 4 GB of free space. Shutdown now."
    sleep 10
    if [ -f /mnt/SDCARD/System/bin/shutdown ]; then
      /mnt/SDCARD/System/bin/shutdown
    else
      poweroff &
    fi
    sleep 30
    # infoscreen.sh -m "CrossMix-OS update requires 4 GB of free space." -t 5
    exit 1
  fi
}

# Function to move files and directories
move_items() {
  # List of directories to exclude
  EXCLUDE_DIRS="
  /mnt/SDCARD/Data
  /mnt/SDCARD/BIOS
  /mnt/SDCARD/Best
  /mnt/SDCARD/Imgs
  /mnt/SDCARD/Roms
  /mnt/SDCARD/_Updates
  $UPDATE_FILE
  "

  for item in /mnt/SDCARD/*; do
    excluded=0
    for excl in $EXCLUDE_DIRS; do
      if echo "$item" | grep -q "$excl"; then
        excluded=1
        break
      fi
    done

    if [ $excluded -eq 0 ]; then
      mv "$item" "$BCK_DIR/"
      sync
    fi
  done

  readme_text="This folder contains a backup of previous CrossMix files.\n
Normally, all saves and save states have been migrated during the automated update process.\n
After an update, it is recommended to keep this folder for some time. Once you have spent some time on CrossMix and verified that all your saves are functional, you can delete this \"_update\" directory to free up storage space on your SD card."

  echo -e "$readme_text" >"/mnt/SDCARD/_Updates/ReadMe.txt"
  sync
}

check_available_space

echo "=========================================================================================="
echo "          ==============  Checking filesystem integrity... =============="
# Check the filesystem
fsck.fat -r -w -a $mount_point

echo "=========================================================================================="
echo "          ==============  Creating backup of old files... =============="
echo "Destination directory: $BCK_DIR"
# Execute the move_items function
move_items

# No BIOS should be here... but just in case
mv "$BCK_DIR/RetroArch/.retroarch/system/"* "/mnt/SDCARD/BIOS" 2>/dev/null
sync

echo "=========================================================================================="
echo "    ==============  Decompressing new CrossMix archive, please wait... =============="
# Install CrossMix new version
echo "CrossMix archive decompression lasts at least 4 minutes."
echo -e "\n\n     !!!!!! Please be patient  !!!!!! \n\n"
/tmp/7zz x -aoa "$UPDATE_FILE" -o"/mnt/SDCARD"
sync

if [ $? -eq 0 ]; then
  echo -e "${GREEN}CrossMix v$update_version extraction successful.${NC}"
  # infoscreen.sh -m "CrossMix v$update_version extraction successful."
  mv "$UPDATE_FILE" "/mnt/SDCARD/_Updates"
else
  echo -ne "${RED}CrossMix v$update_version extraction encountered errors.${NC}\n"
  # infoscreen.sh -m "CrossMix v$update_version extraction encountered errors." -t 5
fi

echo "=========================================================================================="
echo "            ==============  Restore saves and savestates... =============="

# Restore saves and savestates from Retroarch
restore_files "Retroarch saves and savestates"  "$BCK_DIR/RetroArch/.retroarch/saves/"  "/mnt/SDCARD/RetroArch/.retroarch/saves/" "*"
restore_files "Retroarch saves and savestates"  "$BCK_DIR/RetroArch/.retroarch/states/" "/mnt/SDCARD/RetroArch/.retroarch/states/" "*"

# Restore PPSSPP 1.15.4 standalone saves and savestates
restore_files "PPSSPP 1.15.4 saves"             "$BCK_DIR/Emus/PSP/PPSSPP_1.15.4/.config/ppsspp/PSP/SAVEDATA/"      "/mnt/SDCARD/Emus/PSP/PPSSPP_1.15.4/.config/ppsspp/PSP/SAVEDATA/" "*"
restore_files "PPSSPP 1.15.4 savestates"        "$BCK_DIR/Emus/PSP/PPSSPP_1.15.4/.config/ppsspp/PSP/PPSSPP_STATE/"  "/mnt/SDCARD/Emus/PSP/PPSSPP_1.15.4/.config/ppsspp/PSP/PPSSPP_STATE/" "*"
restore_files "PPSSPP 1.15.4 cheats"            "$BCK_DIR/Emus/PSP/PPSSPP_1.15.4/.config/ppsspp/PSP/Cheats/"        "/mnt/SDCARD/Emus/PSP/PPSSPP_1.15.4/.config/ppsspp/PSP/Cheats/" "*.ini"
restore_files "PPSSPP 1.15.4 game settings"     "$BCK_DIR/Emus/PSP/PPSSPP_1.15.4/.config/ppsspp/PSP/SYSTEM/"        "/mnt/SDCARD/Emus/PSP/PPSSPP_1.15.4/.config/ppsspp/PSP/SYSTEM/" "*_ppsspp.ini"

# Restore PPSSPP 1.17.1 standalone saves, savestates and retroachievements (CrossMix path = 1.0.0)
restore_files "PPSSPP 1.17.1 saves"             "$BCK_DIR/Emus/PSP/.config/ppsspp/PSP/SAVEDATA/"       "/mnt/SDCARD/Emus/PSP/PPSSPP_1.17.1/.config/ppsspp/PSP/SAVEDATA/" "*"
restore_files "PPSSPP 1.17.1 savestates"        "$BCK_DIR/Emus/PSP/.config/ppsspp/PSP/PPSSPP_STATE/"   "/mnt/SDCARD/Emus/PSP/PPSSPP_1.17.1/.config/ppsspp/PSP/PPSSPP_STATE/" "*"
restore_files "PPSSPP 1.17.1 retroachievements" "$BCK_DIR/Emus/PSP/.config/ppsspp/PSP/SYSTEM/"         "/mnt/SDCARD/Emus/PSP/PPSSPP_1.17.1/.config/ppsspp/PSP/SYSTEM/" "*.dat"
restore_files "PPSSPP 1.17.1 cheats"            "$BCK_DIR/Emus/PSP/.config/ppsspp/PSP/Cheats/"         "/mnt/SDCARD/Emus/PSP/PPSSPP_1.17.1/.config/ppsspp/PSP/Cheats/" "*.ini"
restore_files "PPSSPP 1.17.1 game assets"       "$BCK_DIR/Emus/PSP/.config/ppsspp/PSP/GAME/"           "/mnt/SDCARD/Emus/PSP/PPSSPP_1.17.1/.config/ppsspp/PSP/GAME/" "*"
restore_files "PPSSPP 1.17.1 textures"          "$BCK_DIR/Emus/PSP/.config/ppsspp/PSP/TEXTURES/"       "/mnt/SDCARD/Emus/PSP/PPSSPP_1.17.1/.config/ppsspp/PSP/TEXTURES/" "*"
restore_files "PPSSPP 1.17.1 game settings"     "$BCK_DIR/Emus/PSP/.config/ppsspp/PSP/SYSTEM/"         "/mnt/SDCARD/Emus/PSP/PPSSPP_1.17.1/.config/ppsspp/PSP/SYSTEM/" "*_ppsspp.ini"

# Restore PPSSPP 1.17.1 standalone saves, savestates and retroachievements (CrossMix path > 1.1.0)
restore_files "PPSSPP 1.17.1 saves"             "$BCK_DIR/Emus/PSP/PPSSPP_1.17.1/.config/ppsspp/PSP/SAVEDATA/"     "/mnt/SDCARD/Emus/PSP/PPSSPP_1.17.1/.config/ppsspp/PSP/SAVEDATA/" "*"
restore_files "PPSSPP 1.17.1 savestates"        "$BCK_DIR/Emus/PSP/PPSSPP_1.17.1/.config/ppsspp/PSP/PPSSPP_STATE/" "/mnt/SDCARD/Emus/PSP/PPSSPP_1.17.1/.config/ppsspp/PSP/PPSSPP_STATE/" "*"
restore_files "PPSSPP 1.17.1 retroachievements" "$BCK_DIR/Emus/PSP/PPSSPP_1.17.1/.config/ppsspp/PSP/SYSTEM/"       "/mnt/SDCARD/Emus/PSP/PPSSPP_1.17.1/.config/ppsspp/PSP/SYSTEM/" "*.dat"
restore_files "PPSSPP 1.17.1 cheats"            "$BCK_DIR/Emus/PSP/PPSSPP_1.17.1/.config/ppsspp/PSP/Cheats/"       "/mnt/SDCARD/Emus/PSP/PPSSPP_1.17.1/.config/ppsspp/PSP/Cheats/" "*.ini"
restore_files "PPSSPP 1.17.1 game assets"       "$BCK_DIR/Emus/PSP/PPSSPP_1.17.1/.config/ppsspp/PSP/GAME/"         "/mnt/SDCARD/Emus/PSP/PPSSPP_1.17.1/.config/ppsspp/PSP/GAME/" "*"
restore_files "PPSSPP 1.17.1 textures"          "$BCK_DIR/Emus/PSP/PPSSPP_1.17.1/.config/ppsspp/PSP/TEXTURES/"     "/mnt/SDCARD/Emus/PSP/PPSSPP_1.17.1/.config/ppsspp/PSP/TEXTURES/" "*"
restore_files "PPSSPP 1.17.1 game settings"     "$BCK_DIR/Emus/PSP/PPSSPP_1.17.1/.config/ppsspp/PSP/SYSTEM/"       "/mnt/SDCARD/Emus/PSP/PPSSPP_1.17.1/.config/ppsspp/PSP/SYSTEM/" "*_ppsspp.ini"

# Restore Drastic saves and savestates
restore_files "Drastic saves"                   "$BCK_DIR/Emus/NDS/drastic/backup/"         "/mnt/SDCARD/Emus/NDS/drastic/backup/" "*"
restore_files "Drastic savestates"              "$BCK_DIR/Emus/NDS/drastic/savestates/"     "/mnt/SDCARD/Emus/NDS/drastic/savestates/" "*"

# Restore previous recordings
restore_files "Video recordings"                "$BCK_DIR/Apps/ScreenRecorder/output/"      "/mnt/SDCARD/Apps/ScreenRecorder/output/" "*.mp4"

# Restore PortMaster squashfs images
restore_files "PortMaster squashfs images"      "$BCK_DIR/Apps/PortMaster/PortMaster/libs/" "/mnt/SDCARD/Apps/PortMaster/PortMaster/libs/" "*"



repair_rom_path() {
  local src_path=$1
  local dest_path=$2

  if [ -d "$src_path" ]; then
    if [ "$(ls -A "$src_path")" ]; then
      mkdir -p "$dest_path"
      mv "$src_path"/* "$dest_path/"
      rm "$dest_path/"*.db
    fi
    rmdir "$src_path"
  fi
}

echo "=========================================================================================="
echo "          ==============  Fix potential bad Roms folders... =============="
repair_rom_path "/mnt/SDCARD/Roms/PPSSPP" "/mnt/SDCARD/Roms/PSP"
repair_rom_path "/mnt/SDCARD/Roms/3DO" "/mnt/SDCARD/Roms/PANASONIC"
repair_rom_path "/mnt/SDCARD/Roms/OPERA" "/mnt/SDCARD/Roms/PANASONIC"
repair_rom_path "/mnt/SDCARD/Roms/ARCADE_FBNEO" "/mnt/SDCARD/Roms/FBNEO"
repair_rom_path "/mnt/SDCARD/Roms/PICO8" "/mnt/SDCARD/Roms/PICO"
repair_rom_path "/mnt/SDCARD/Roms/FFMPEG" "/mnt/SDCARD/Roms/VIDEOS"
repair_rom_path "/mnt/SDCARD/Roms/32X" "/mnt/SDCARD/Roms/SEGA32X"
repair_rom_path "/mnt/SDCARD/Roms/COL" "/mnt/SDCARD/Roms/COLECO"
repair_rom_path "/mnt/SDCARD/Roms/INT" "/mnt/SDCARD/Roms/INTELLIVISION"
repair_rom_path "/mnt/SDCARD/Roms/SCD" "/mnt/SDCARD/Roms/SEGACD"
repair_rom_path "/mnt/SDCARD/Roms/SS" "/mnt/SDCARD/Roms/SATURN"
repair_rom_path "/mnt/SDCARD/Roms/SNES" "/mnt/SDCARD/Roms/SFC"
repair_rom_path "/mnt/SDCARD/Roms/NES" "/mnt/SDCARD/Roms/FC"
repair_rom_path "/mnt/SDCARD/Roms/MEGADRIVE" "/mnt/SDCARD/Roms/MD"
repair_rom_path "/mnt/SDCARD/Roms/GENESIS" "/mnt/SDCARD/Roms/MD"
repair_rom_path "/mnt/SDCARD/Roms/DS" "/mnt/SDCARD/Roms/NDS"

# Move ScummVM games to "GAMES" subfolder
for item in /mnt/SDCARD/Roms/SCUMMVM/*; do
  basename_item="$(basename "$item")"
  case "$basename_item" in
  "° Import ScummVM Games.launch" | "° Run ScummVM.launch" | "GAMES") ;;
  *)
    mv "$item" "/mnt/SDCARD/Roms/SCUMMVM/GAMES/"
    rm "/mnt/SDCARD/Roms/SCUMMVM/GAMES/"*.db
    ;;
  esac
done

# be sure that the PortMaster python install will be triggered
rm "/mnt/SDCARD/System/bin/python3"

# be sure that some CrossMix apps are refreshed
rm /mnt/SDCARD/Apps/SystemTools/Menu/Menu_cache7.db
rm /mnt/SDCARD/Apps/Scraper/Menu/Menu_cache7.db

echo "=========================================================================================="
echo "       ==============  Installation completed, rebooting in 10 seconds... =============="

echo ondemand >/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
echo 1008000 >/sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq
echo 1008000 >/sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq
rm /tmp/stay_awake
sync
sleep 10

if [ -f /mnt/SDCARD/System/bin/shutdown ]; then
  /mnt/SDCARD/System/bin/shutdown -r
else
  reboot &
fi
sleep 30
