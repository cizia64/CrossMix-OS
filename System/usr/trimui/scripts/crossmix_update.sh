#!/bin/sh
source /mnt/SDCARD/System/usr/trimui/scripts/update_common.sh

echo performance >/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
echo 1608000 >/sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq


main() {
# Find the update file
UPDATE_FILE=$(find /mnt/SDCARD -maxdepth 1 -name "CrossMix-OS_v*.zip" -print -quit)

if [ -n "$UPDATE_FILE" ]; then
  script_dir=$(dirname "$(realpath "$0")")
  if [ "$script_dir" != "/tmp" ]; then
    /mnt/SDCARD/System/bin/7zz e "$UPDATE_FILE" "System/usr/trimui/scripts/crossmix_update.sh" -o/tmp -y
    chmod a+x "/tmp/crossmix_update.sh"
    sh "/tmp/crossmix_update.sh"
    exit
  fi
else
  echo "No update file found"
  exit
fi


if [ -z "$Local_CrossMixVersion" ]; then
  Local_CrossMixVersion="x"
fi
update_version=$(echo "$UPDATE_FILE" | awk -F'_v|\.zip' '{print $2}')

cp /mnt/SDCARD/System/bin/7zz /tmp
rm -rf "/mnt/SDCARD/System Volume Information"
echo 1 >/tmp/stay_awake

# Create backup directory
BCK_DIR="/mnt/SDCARD/_Updates/Backup_CrossMix_v$Local_CrossMixVersion"


if [ -d "$BCK_DIR" ]; then
  BCK_DIR="${BCK_DIR}_$timestamp"
fi
mkdir -p "$BCK_DIR"
sync

LOG_FILE="/mnt/SDCARD/_Updates/CrossMix_v${update_version}_${timestamp}.log"
exec > >(tee -a "$LOG_FILE") 2>&1

# echo "==============  Updating CrossMix-OS v$Local_CrossMixVersion to v$update_version  =============="
echo "${BLUE}======  Updating CrossMix-OS v$Local_CrossMixVersion to v$update_version  ======{NC}"

check_available_space "5000"
    if [ $? -eq 1 ]; then
        echo -ne "${YELLOW}"
        read -n 1 -s -r -p "Press A to exit"
        exit 3
    fi

check_filesystem

echo "${BLUE}==============          Creating backup of old files...           =============={NC}"

echo "Destination directory: $BCK_DIR"
# Execute the move_items function
move_items

# No BIOS should be here... but just in case
mv "$BCK_DIR/RetroArch/.retroarch/system/"* "/mnt/SDCARD/BIOS" 2>/dev/null
sync

echo "${BLUE}=============  Decompressing new CrossMix archive, please wait...  ============={NC}"
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

echo "${BLUE}=====================  Restoring saves and savestates...  ====================={NC}"

# Restore saves and savestates from Retroarch
restore_files "Retroarch saves"  "$BCK_DIR/RetroArch/.retroarch/saves/"  "/mnt/SDCARD/RetroArch/.retroarch/saves/" "*"
restore_files "Retroarch savestates"  "$BCK_DIR/RetroArch/.retroarch/states/" "/mnt/SDCARD/RetroArch/.retroarch/states/" "*"
restore_files "Retroarch cheats"  "$BCK_DIR/RetroArch/.retroarch/cheats/" "/mnt/SDCARD/RetroArch/.retroarch/cheats/" "*"
restore_files "Retroarch database"  "$BCK_DIR/RetroArch/.retroarch/database/" "/mnt/SDCARD/RetroArch/.retroarch/database/" "*"
restore_files "Retroarch filters"  "$BCK_DIR/RetroArch/.retroarch/filters/" "/mnt/SDCARD/RetroArch/.retroarch/filters/" "*" No_Overwrite
restore_files "Retroarch playlists"  "$BCK_DIR/RetroArch/.retroarch/playlists/" "/mnt/SDCARD/RetroArch/.retroarch/playlists/" "*"
restore_files "Retroarch screenshots"  "$BCK_DIR/RetroArch/.retroarch/screenshots/" "/mnt/SDCARD/RetroArch/.retroarch/screenshots/" "*"
restore_files "Retroarch shaders"  "$BCK_DIR/RetroArch/.retroarch/shaders/" "/mnt/SDCARD/RetroArch/.retroarch/shaders/" "*" No_Overwrite
restore_files "Retroarch thumbnails"  "$BCK_DIR/RetroArch/.retroarch/thumbnails/" "/mnt/SDCARD/RetroArch/.retroarch/thumbnails/" "*"


# Restore Retroarch settings
SOURCE_FILE="$BCK_DIR/RetroArch/retroarch.cfg"
TARGET_FILE="/mnt/SDCARD/RetroArch/retroarch.cfg"
KEYS="cheevos_username cheevos_password cheevos_token cheevos_enable"

extract_keys "$KEYS" "$SOURCE_FILE" "$TARGET_FILE"

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

# DC Standalone RetroAchievements
SOURCE_FILE="$BCK_DIR/Emus/DC/flycast_v2.4/config/emu.cfg"
TARGET_FILE="/mnt/SDCARD/Emus/DC/flycast_v2.4/config/emu.cfg"
KEYS="Enabled HardcoreMode UserName Token"
extract_keys "$KEYS" "$SOURCE_FILE" "$TARGET_FILE"

# DC BIOS files new location
restore_files "Restore DC BIOS files"           "$BCK_DIR/BIOS/dc/" "/mnt/SDCARD/BIOS/dc/flycast/" "*.bin"

# Restore PICO-8 binaries & Splore BBS games
restore_files "Restore PICO-8 binaries"         "$BCK_DIR/Emus/PICO/PICO8_Wrapper/bin/" "/mnt/SDCARD/Emus/PICO/PICO8_Wrapper/bin/" "*"
restore_files "Restore PICO-8 Splore games"     "/mnt/SDCARD/Emus/PICO/PICO8_Wrapper/.lexaloffle/pico-8/bbs/carts" "/mnt/SDCARD/Roms/PICO/splore" "*"

# PortMaster themes and runtimes
move_without_replace "Restore PortMaster themes"       "$BCK_DIR/Apps/PortMaster/PortMaster/themes/" "/mnt/SDCARD/Apps/PortMaster/PortMaster/themes/"
restore_files "Restore PortMaster runtimes"      "$BCK_DIR/Apps/PortMaster/PortMaster/libs/"  "/mnt/SDCARD/Apps/PortMaster/PortMaster/libs/" "*"

# Restore previous recordings
restore_files "Video recordings"                "$BCK_DIR/Apps/ScreenRecorder/output/"      "/mnt/SDCARD/Apps/ScreenRecorder/output/" "*.mp4"

# Restore Tailscale configuration
restore_files "Restore Tailscale configuration" "$BCK_DIR/System/etc/tailscale/" "/mnt/SDCARD/System/etc/tailscale" "*"

# Restore Syncthings configuration
restore_files "Restore Syncthings configuration" "$BCK_DIR/System/etc/syncthing/" "/mnt/SDCARD/System/etc/syncthing" "*"

# Ebook Reader
move_without_replace "Restore Ebooks"            "$BCK_DIR/Apps/EbookReader/.mreader_store/" "/mnt/SDCARD/Apps/EbookReader/.mreader_store/"
restore_files "Restore Ebook Reader settings"    "$BCK_DIR/Apps/EbookReader/Books/"          "/mnt/SDCARD/Apps/EbookReader/Books/"          "*"

# Music Player
restore_files "Restore Music Player current playlist"  "$BCK_DIR/Apps/MusicPlayer/.local/" "/mnt/SDCARD/Apps/MusicPlayer/.local/" "*"

# Additional user libs (without sub directories)
/mnt/SDCARD/System/bin/rsync  -f"- */" -f"+ *"  -av  "$BCK_DIR/System/lib/" "/mnt/SDCARD/System/lib/" --ignore-existing

# Additional user bin files (with sub directories)
restore_files "Restore additional bin files" "$BCK_DIR/System/bin/" "/mnt/SDCARD/System/bin/" "*" "--ignore-existing"

# Restore CrossMix settings
jq -s '.[1] * .[0]' $BCK_DIR/System/etc/crossmix.json /mnt/SDCARD/System/etc/crossmix.json >/tmp/crossmix.json && mv /tmp/crossmix.json /mnt/SDCARD/System/etc/crossmix.json
sync

# Restore current Retroarch overlay setting
echo "${BLUE}=====================  Restoring Overlays/Ratio settings...  ====================={NC}"

overlay_setting=$(/mnt/SDCARD/System/bin/jq -r '.["OVERLAYS"]' "/mnt/SDCARD/System/etc/crossmix.json")
if [ ! "$overlay_setting" = "Overlays - max ratio" ]; then
  "/mnt/SDCARD/Apps/SystemTools/Menu/EMULATORS##OVERLAYS (value)/$overlay_setting.sh" -s
fi


# Restore Scraper settings
jq -s '.[1] * .[0]' $BCK_DIR/System/etc/scraper.json /mnt/SDCARD/System/etc/scraper.json >/tmp/scraper.json && mv /tmp/scraper.json /mnt/SDCARD/System/etc/scraper.json
sync

# restore user additional themes, icons, Backgrounds
move_without_replace "Restore Themes"                   "$BCK_DIR/Backgrounds/" "/mnt/SDCARD/Backgrounds/"
move_without_replace "Restore Backgrounds"              "$BCK_DIR/Backgrounds/" "/mnt/SDCARD/Backgrounds/"
move_without_replace "Restore Icons"                    "$BCK_DIR/Icons/"       "/mnt/SDCARD/Icons/"

echo "${BLUE}======================  Fix potential bad Roms folders... ======================{NC}"

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

echo "${BLUE}============== Installation completed, rebooting in 10 seconds... =============={NC}"


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

}


restore_files() {
  # Copy with overwrite
  local NAME="$1"
  local SRC_DIR="$2"
  local DST_DIR="$3"
  local FILE_PATTERN="$4"
  local OPTION="$5"

  if [ "$OPTION" = "No_Overwrite" ]; then
    OPTION="--ignore-existing"
  fi
  if [ -z "$FILE_PATTERN" ]; then
    FILE_PATTERN="*"
  fi
  echo "------------------------------------------------------------------------------"
  if [ -n "$(find "$SRC_DIR" -mindepth 1 -name "$FILE_PATTERN" -print -quit 2>/dev/null)" ]; then
    echo -e "$NAME: restoring files...\n"
    mkdir -p "$DST_DIR"
    /mnt/SDCARD/System/bin/rsync --stats -av $OPTION --include="*/" --include="$FILE_PATTERN" --exclude="*" "$SRC_DIR/" "$DST_DIR/"
    sync
  else
    echo "$NAME: No files to restore."
  fi
}

move_without_replace() {
  local NAME="$1"
  local SRC_DIR="$2"
  local DST_DIR="$3"

  [ -d "$SRC_DIR" ] || {
    echo "Source directory $SRC_DIR missing."
    return 1
  }
  mkdir -p "$DST_DIR"

  echo "------------------------------------------------------------------------------"

  echo -e "$NAME: moving files...\n"

  for item in "$SRC_DIR"/*; do
    [ -e "$item" ] || continue
    item_name=$(basename "$item")
    [ -e "$DST_DIR/$item_name" ] || mv "$item" "$DST_DIR/"
  done
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

  readme_text="This folder contains a backup of previous CrossMix v$Local_CrossMixVersion files.\n
Normally, all saves and save states have been migrated during the automated update process.\n
After an update, it is recommended to keep this folder for some time. Once you have spent some time on CrossMix and verified that all your saves and settings are functional, you can delete this \"_update\" directory to free up storage space on your SD card."

  echo -e "$readme_text" >"/mnt/SDCARD/_Updates/ReadMe.txt"
  sync
}

# Function to copy specified keys from a RetroArch configuration file to another
extract_keys() {
  local keys="$1"        # Space-separated list of keys
  local source_file="$2" # Source configuration file
  local target_file="$3" # Target file to save the extracted keys

  local temp_file=$(mktemp)

  for key in $keys; do
    grep "^$key" "$source_file" >>"$temp_file"
  done

  /mnt/SDCARD/System/usr/trimui/scripts/patch_ra_cfg.sh "$temp_file" "$target_file"

  echo "The following keys have been exported to $target_file:"
  echo "$keys"
}

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

main
