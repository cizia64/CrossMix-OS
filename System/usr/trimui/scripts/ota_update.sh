#!/bin/sh

export LD_LIBRARY_PATH="/mnt/SDCARD/System/lib:/usr/trimui/lib:$LD_LIBRARY_PATH"
# Repository name :
GITHUB_REPOSITORY=cizia64/CrossMix-OS

# Colors
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m' # No Color

clear

check_connection() {
	echo -n "Checking internet connection... "
	if /mnt/SDCARD/System/bin/wget -q --spider https://github.com >/dev/null; then
		echo -e "${GREEN}OK${NC}"
	else
		echo -e "${RED}FAIL${NC}\nError: https://github.com not reachable.\nCheck your wifi connection."
		echo -ne "${YELLOW}"
		sleep 5
		killall -2 SimpleTerminal
	fi
}

run_bootstrap() {
	curl -k -s https://raw.githubusercontent.com/$GITHUB_REPOSITORY/main/_assets/scripts/ota_bootstrap.sh | sh
}
get_release_info() {
	Current_Version=$(cat /mnt/SDCARD/System/usr/trimui/crossmix-version.txt)
	echo -ne "\n\n" \
		"${BLUE}======= Installed Version ========${NC}\n" \
		" Version: $Current_Version \n" \
		"${BLUE}==================================${NC}\n"
}

get_release_info
check_connection
run_bootstrap
