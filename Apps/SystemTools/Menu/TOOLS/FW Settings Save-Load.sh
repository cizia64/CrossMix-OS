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

# Function to show help
show_help() {
  echo "Usage: $0 [OPTIONS]"
  echo ""
  echo "Options:"
  echo "  -h, --help                    Show this help message"
  echo "  -b, --backup                  Create a backup"
  echo "  -r, --restore FILE [TYPE]     Restore from backup file"
  echo ""
  echo "Restore types (optional):"
  echo "  all                           Restore all settings (default)"
  echo "  wifi                          Restore only wifi settings"
  echo "  joystick                      Restore only joystick calibration"
  echo "  mainui                        Restore only MainUI settings"
  echo ""
  echo "Examples:"
  echo "  $0 --backup"
  echo "  $0 --restore /path/to/backup.7z"
  echo "  $0 --restore /path/to/backup.7z wifi"
}

# Parse command line arguments
if [ $# -gt 0 ]; then
  case "$1" in
  -h | --help)
    show_help
    exit 0
    ;;
  -b | --backup)
    selected_action="Backup"
    ;;
  -r | --restore)
    if [ -z "$2" ]; then
      echo "Error: Backup file path required for restore operation"
      show_help
      exit 1
    fi
    selected_action="Restore"
    ARCHIVE_PATH="$2"
    restore_type="${3:-all}"
    ;;
  *)
    echo "Error: Unknown option '$1'"
    show_help
    exit 1
    ;;
  esac
else
  # Interactive mode - use selector
  selector_output=$(selector -t "Choose an action to perform:                           (B to cancel)" -c "Backup" "Restore")
  selected_action="${selector_output#*: }"
fi

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
    mnt/UDISK/joypad_right.config \
    root/.ash_history

  # Show info screen only in interactive mode
  if [ $# -eq 0 ]; then
    infoscreen.sh -m "\"backup_$(date +'%Y%m%d-%Hh%M-%S').7z\"    saved." -t 2
  else
    echo "backup_$(date +'%Y%m%d-%Hh%M-%S').7z"
  fi

  sync
  ;;

"Restore")

  echo "Restore mode"

  # If not in command line mode, ask the user to select the backup file
  if [ -z "$ARCHIVE_PATH" ]; then
    selector_output=$(selector -t "Choose a backup file to restore:" -d "/mnt/SDCARD/System/backups/firmware_settings/$current_device/")
    echo "$cleaned_input" | grep -q "No file selected" && {
      infoscreen.sh -m "Exiting..." -t 1
      exit 0
    }
    ARCHIVE_PATH="${selector_output#*: }"
  fi

  # Check if the backup archive file exists
  if [ ! -f "$ARCHIVE_PATH" ]; then
    echo "Backup archive not found: $ARCHIVE_PATH"
    exit 1
  fi

  # If not in command line mode, ask what to restore
  if [ -z "$restore_type" ]; then
    selector_output=$(selector -t "Choose what you want to restore:" -c "All" "Wifi settings" "Joystick calibration" "MainUI settings")
    selected_restore="${selector_output#*: }"
    case "$selected_restore" in
    "All") restore_type="all" ;;
    "Wifi settings") restore_type="wifi" ;;
    "Joystick calibration") restore_type="joystick" ;;
    "MainUI settings") restore_type="mainui" ;;
    *) restore_type="all" ;;
    esac
  fi

  case "$restore_type" in
  "all")
    $SEVENZ x "$ARCHIVE_PATH" -y -o/ >/dev/null 2>&1 && echo "All settings restored."
    restore_message="All settings restored."
    ;;
  "wifi")
    restore_file "/etc/wifi/wpa_supplicant.conf"
    restore_message="Wifi settings restored."
    ;;
  "joystick")
    restore_file "/mnt/UDISK/joypad.config"
    restore_message="Joystick calibration restored."
    ;;
  "mainui")
    restore_file "/mnt/UDISK/system.json"
    restore_message="MainUI settings restored."
    ;;
  *)
    echo "No valid option selected."
    # Show info screen only in interactive mode
    if [ $# -eq 0 ]; then
      infoscreen.sh -m "Exiting..."
    fi
    exit 1
    ;;
  esac

  # Show info screen only in interactive mode
  if [ $# -eq 0 ]; then
    infoscreen.sh -m "$restore_message" -t 2
  else
    echo "$restore_message"
  fi

  sync
  ;;

*)
  # If no valid action is selected (B pressed), exit
  echo "No valid action selected."
  # Show info screen only in interactive mode
  if [ $# -eq 0 ]; then
    infoscreen.sh -m "Exiting..."
  fi
  exit 1
  ;;
esac
