#!/bin/sh
source /mnt/SDCARD/System/usr/trimui/scripts/update_common.sh

run_bootstrap() {
	curl -k -s https://raw.githubusercontent.com/$GITHUB_REPOSITORY/main/_assets/scripts/ota_bootstrap.sh | sh
}

Upgrade_UpdateScripts() {
	download_file "crossmix_update.sh" "https://raw.githubusercontent.com/cizia64/CrossMix-OS/refs/heads/main/System/usr/trimui/scripts/crossmix_update.sh" -d "/mnt/SDCARD/System/usr/trimui/scripts/"
	download_file "update_ota_release.sh" "https://raw.githubusercontent.com/cizia64/CrossMix-OS/refs/heads/main/System/usr/trimui/scripts/update_ota_release.sh" -d "/mnt/SDCARD/System/usr/trimui/scripts/"
	download_file "update_common.sh" "https://raw.githubusercontent.com/cizia64/CrossMix-OS/refs/heads/main/System/usr/trimui/scripts/update_common.sh" -d "/mnt/SDCARD/System/usr/trimui/scripts/"
}

main() {
	check_connection
	clear
	Upgrade_UpdateScripts
	sleep 3
	run_bootstrap
	clear

	echo -e "\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n\n" >>"$updatedir/ota_release.log"
	echo -e "${timestamp}\n" >>"$updatedir/ota_release.log"
	/mnt/SDCARD/System/usr/trimui/scripts/update_ota_release.sh | tee -a "$updatedir/ota_release.log"

	# if there is no release to apply, we check if there is hotfix for this version
	if grep -q -E "^(no release|user cancel)$" "/tmp/ota_release_result"; then # "no release", "user cancel", "download failed", "success"
		url="https://raw.githubusercontent.com/$GITHUB_REPOSITORY/main/_assets/hotfixes/CrossMix-OS_v$Local_CrossMixVersion.sh"

		if /mnt/SDCARD/System/bin/wget -q --spider "$url"; then

			echo -e "\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n\n" >>"$updatedir/ota_hotfix.log"
			echo -e "${timestamp}\n" >>"$updatedir/ota_hotfix.log"
			curl -k -s "$url" | sh | tee -a "$updatedir/ota_hotfix.log"

		else
			clear
			echo -ne "${PURPLE}Retrieving hotfix information.. ${NC}"
			echo -ne "${GREEN}DONE${NC}\n\n\n"
			echo -e "No hotfix available for CrossMix v$Local_CrossMixVersion.\n"
			echo -ne "${YELLOW}"
			read -n 1 -s -r -p "Press A to exit"
		fi
	fi
	sleep 2
	killall -2 SimpleTerminal

}

main
