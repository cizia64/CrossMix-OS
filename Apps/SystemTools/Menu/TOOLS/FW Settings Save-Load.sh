#!/bin/sh
export LD_LIBRARY_PATH=./lib:/mnt/SDCARD/System/lib:$LD_LIBRARY_PATH
export PATH="/mnt/SDCARD/System/bin:/mnt/SDCARD/System/usr/trimui/scripts:$PATH"
SEVENZ="/mnt/SDCARD/System/bin/7zz"

# Function to restore individual files from the archive
restore_file() {
  path="$1"
  relative_path="${path#/}" # Remove leading "/" from the path
  [ -n "$relative_path" ] && $SEVENZ x "$ARCHIVE_PATH" "$relative_path" -y -o/ && echo "Restored: $path"
  chmod 644 "$path"
  chown root:root "$path"
}

if ! read -r current_device </etc/trimui_device.txt; then
  RES=$(fbset | awk '/geometry/ {print $2 "x" $3}')
  if [ "$RES" = "1280x720" ]; then
    current_device="tsp"
  else
    current_device="brick"
  fi
  echo -n $current_device >/etc/trimui_device.txt

fi

selector_output=$(selector -t "Choose an action to perform:                           (B to cancel)" -c "Backup" "Restore")
selected_action="${selector_output#*: }"

case "$selected_action" in
"Backup")
  echo "Backup mode"
  ARCHIVE_PATH="/mnt/SDCARD/System/backups/firmware_settings/$current_device/backup_$(date +'%Y%m%d-%Hh%M-%S').7z"
  mkdir -p "/mnt/SDCARD/System/backups/firmware_settings/$current_device/"
  cd /

  # Create the backup archive including the specified files
  $SEVENZ a "$ARCHIVE_PATH" \
    etc/wifi/wpa_supplicant.conf \
    mnt/UDISK/system.json \
    mnt/UDISK/joypad.config \
    root/.ash_history

  infoscreen.sh -m "\"backup_$(date +'%Y%m%d-%Hh%M-%S').7z\"    saved." -t 2

  sync
  ;;

"Restore")

  echo "Restore mode"

  # Ask the user to select the backup file to restore
  selector_output=$(selector -t "Choose a backup file to restore:" -d "/mnt/SDCARD/System/backups/firmware_settings/$current_device/")
  echo "$cleaned_input" | grep -q "No file selected" && {
    infoscreen.sh -m "Exiting..." -t 1
    exit 0
  }

  ARCHIVE_PATH="${selector_output#*: }"

  # Check if the backup archive file exists
  if [ ! -f "$ARCHIVE_PATH" ]; then
    echo "Backup archive not found: $ARCHIVE_PATH"
    exit 1
  fi

  selector_output=$(selector -t "Choose what you want to restore:" -c "All" "Wifi settings" "Joystick calibration" "MainUI settings")
  selected_action="${selector_output#*: }"

  case "$selected_action" in
  "All")
    $SEVENZ x "$ARCHIVE_PATH" -y -o/ >/dev/null 2>&1 && echo "All settings restored."
    ;;
  "Wifi settings")
    restore_file "/etc/wifi/wpa_supplicant.conf"
    ;;
  "Joystick calibration")
    restore_file "/mnt/UDISK/joypad.config"
    ;;
  "MainUI settings")
    restore_file "/mnt/UDISK/system.json"
    ;;
  *)
    echo "No valid option selected."
    infoscreen.sh -m "Exiting..."
    exit 1
    ;;
  esac

  infoscreen.sh -m "$selected_action is restored." -t 2

  sync
  ;;

*)
  # If no valid action is selected (B pressed), exit
  echo "No valid action selected."
  infoscreen.sh -m "Exiting..."
  exit 1
  ;;
esac
