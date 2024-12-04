#!/bin/sh
export PATH="/mnt/SDCARD/System/usr/trimui/scripts/:/mnt/SDCARD/System/bin:/usr/trimui/bin:$PATH"
export LD_LIBRARY_PATH="/mnt/SDCARD/System/lib:/mnt/SDCARD/Apps/PortMaster/PortMaster:/usr/trimui/lib:$LD_LIBRARY_PATH"

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
BLUE='\033[1;34m'
ORANGE='\033[01;38;5;214m'
NC='\033[0m' # No Color

CONFIG_FILE="/mnt/SDCARD/Apps/PortMaster/PortMaster/config/runtimes.json"
LOCAL_DIR="/mnt/SDCARD/Apps/PortMaster/PortMaster/libs"
SEARCH_DIRS="/mnt/SDCARD/Roms/PORTS"

MISSING_FILES="/tmp/missing_files.txt"
INVALID_FILES="/tmp/invalid_files.txt"
: >"$MISSING_FILES"
: >"$INVALID_FILES"

echo -e "\n${YELLOW}Checking requirements...${NONE}"
echo "------------------------"

# Ensure jq is installed
if ! command -v jq >/dev/null; then
  echo -e "${RED}Error: jq is not installed.${NC}"
  exit 1
fi

# Ensure the configuration file exists
if [ ! -f "$CONFIG_FILE" ]; then
  echo -e "runtimes.json:${RED} not found${NC}"
  echo -e "Generating a fresh PortMaster configuration...\n"
  /mnt/SDCARD/Apps/PortMaster/PortMaster/harbourmaster update --quiet >/dev/null 2>&1
fi

# Function to check if a runtime file is used by current ports
is_file_referenced() {
  local file="$1"
  for dir in $SEARCH_DIRS; do
    if grep -q "$file" "$dir"/*.sh 2>/dev/null; then
      return 0
    fi
  done
  return 1
}

# Function to download a runtime file
download_file() {
  local file="$1"
  local url="$2"
  local runtime_size="$3"
  local local_file="$LOCAL_DIR/$file"

  if ! is_file_referenced "$file"; then
    echo -e "  \"$file\" ${ORANGE}skipped (not used)${NC}"
    return
  fi

  # Check available space
  local mount_point
  mount_point=$(mount | grep -m 1 '/mnt/SDCARD' | awk '{print $1}')
  local available_space
  available_space=$(df -m "$mount_point" | awk 'NR==2 {print $4}')
  local required_space=$((runtime_size / 1048576 + 100))

  if [ "$available_space" -lt "$required_space" ]; then
    echo -e "${RED}Insufficient space for $file. Needed: ${required_space}MB, Available: ${available_space}MB.${NC}"
    return
  fi

  echo "Downloading $file..."
  mkdir -p "$LOCAL_DIR"
  wget -q -O "$local_file" "$url"
  if [ $? -ne 0 ]; then
    echo -e "  \"$file\" ${RED}download KO${NC}"
    rm -f "$local_file"
  else
    echo -e "  \"$file\" ${GREEN}download OK${NC}"
  fi
}

echo -e "\n${YELLOW}Checking runtime files integrity...${NONE}"
echo "-----------------------------------"

# Process scan existing runtimes
jq -r 'keys[]' "$CONFIG_FILE" | while read -r file; do
  url=$(jq -r --arg file "$file" '.[$file].remote.aarch64.url' "$CONFIG_FILE")
  expected_crc=$(jq -r --arg file "$file" '.[$file].remote.aarch64.md5' "$CONFIG_FILE")

  if [ "$url" = "null" ] || [ -z "$expected_crc" ]; then
    echo -e "  ${ORANGE}No URL or CRC provided for $file, skipping.${NC}"
    continue
  fi

  local_file="$LOCAL_DIR/$file"
  if [ ! -f "$local_file" ]; then
    echo -e "  $file  ${RED}missing${NC}"
    echo "$file" >>"$MISSING_FILES"
    continue
  fi

  actual_crc=$(md5sum "$local_file" | awk '{print $1}')
  if [ "$actual_crc" != "$expected_crc" ]; then
    echo -e "  $file ${RED}invalid checksum${NC}. Removing file."
    rm -f "$local_file"
    echo "$file" >>"$INVALID_FILES"
  else
    echo -e "  $file ${GREEN}valid${NC}"
  fi
done
echo "Done."
sleep 5

echo
# Download invalid files
echo -e "\n${YELLOW}Downloading invalid files${NC}"
echo "-------------------------"
while read -r file; do
  url=$(jq -r --arg file "$file" '.[$file].remote.aarch64.url' "$CONFIG_FILE")
  runtime_size=$(jq -r --arg file "$file" '.[$file].remote.aarch64.size' "$CONFIG_FILE")
  download_file "$file" "$url" "$runtime_size"
done <"$INVALID_FILES"
echo "Done."
sleep 2

# Prompt for missing files
echo
echo -e "\n${YELLOW}Downloading missing files${NC}"
echo "-------------------------"
while read -r file; do
  url=$(jq -r --arg file "$file" '.[$file].remote.aarch64.url' "$CONFIG_FILE")
  runtime_size=$(jq -r --arg file "$file" '.[$file].remote.aarch64.size' "$CONFIG_FILE")
  download_file "$file" "$url" "$runtime_size"
done <"$MISSING_FILES"
echo "Done."
sleep 2

# Cleanup
rm -f "$MISSING_FILES" "$INVALID_FILES"
echo -e "\n${YELLOW}All operations completed.${NC}"
echo "-------------------------"

if ! pgrep -f "portmaster_fix.sh" >/dev/null; then
  if pgrep "SimpleTerminal" >/dev/null; then
    echo -e "${PURPLE}Exiting in 10 seconds...${NONE}\n"
    sleep 15
    echo "exiting"
    killall -2 SimpleTerminal
  fi
fi
