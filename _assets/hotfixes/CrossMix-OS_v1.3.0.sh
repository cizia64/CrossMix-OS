#!/bin/sh
source /mnt/SDCARD/System/usr/trimui/scripts/update_common.sh
cmd=$1
############### This section must be updated manually at each script update ###############
Remote_HotfixVersion="1.3.0.1"
Remote_HotfixDate="2024-12-23"
Remote_HotfixDesc="- Fix USB Storage App exit\n- Fix Saturn extlist (chd not displayed in rom list)"
###########################################################################################

main() {

    # check_connection
    clear
    if [ "$cmd" == "check" ]; then
        IP=$(ip route get 1 | awk '{print $NF;exit}')
        if [ "$IP" != "" ]; then
            get_hotfix_info
            if [ $? -eq 0 ]; then
                exit 0
            fi
        fi
        exit 1
    fi

    get_hotfix_info
    sleep 8
    if [ $? -eq 1 ]; then
        echo -ne "${YELLOW}"
        read -n 1 -s -r -p "Press A to exit"
        exit 3
    else
        touch "$updatedir/.CrossMixHotfixAvailable"
    fi
    echo -ne "${YELLOW}"
    read -n 1 -s -r -p "Press A to continue"
    echo -ne "${NC}\n"

    check_available_space "$(($Hotfix_size_MB + 100))"
    if [ $? -eq 1 ]; then
        echo -ne "${YELLOW}"
        read -n 1 -s -r -p "Press A to exit"
        exit 3
    fi

    Mychoice=$(echo -e "No\nYes" | /mnt/SDCARD/System/usr/trimui/scripts/shellect.sh -t "Apply hotfix $Remote_HotfixVersion now ?" -b "Press A to validate your choice.")
    clear
    if [ "$Mychoice" = "Yes" ]; then
        # check_filesystem
        if [ ! "$Hotfix_size" = "No additional file" ]; then
            download_file $hotfix_fileUrl -f "$updatedir/CrossMix_hotfix_v$Remote_HotfixVersion.zip" -t "Downloading Hotfix v$Remote_HotfixVersion"
        fi
        apply_update
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}Hotfix v$Remote_HotfixVersion successful.\n${NC}"
            echo $Remote_HotfixVersion >/mnt/SDCARD/System/usr/trimui/crossmix-hotfix-version.txt
            rm "$updatedir/CrossMix_hotfix_v$Remote_HotfixVersion.zip" 2>/dev/null
            rm "$updatedir/.CrossMixHotfixAvailable" 2>/dev/null
        fi
        sync
        sleep 5

        if [ -f /tmp/mustReboot ]; then
            if [ -f /mnt/SDCARD/System/bin/shutdown ]; then
                /mnt/SDCARD/System/bin/shutdown -r
            else
                reboot &
            fi
            sleep 30
        fi
    fi
}

# Compare the versions
get_hotfix_info() {
    echo -ne "${PURPLE}Retrieving hotfix information.. ${NC}"

    if [ -f /mnt/SDCARD/System/usr/trimui/crossmix-hotfix-version.txt ]; then
        Local_HotfixVersion=$(cat /mnt/SDCARD/System/usr/trimui/crossmix-hotfix-version.txt)
        displayedVersion="$Local_HotfixVersion"
    else
        Local_HotfixVersion=$(echo "$Remote_HotfixVersion" | sed 's/\(.*\).$/\10/')
        displayedVersion="$Local_HotfixVersion (no hotfix installed)"
    fi

    hotfix_fileUrl="https://raw.githubusercontent.com/$GITHUB_REPOSITORY/main/_assets/hotfixes/CrossMix-OS_v$Local_CrossMixVersion.zip"

    if wget -q --spider "$hotfix_fileUrl" >/dev/null; then

        size_bytes=$(curl-aarch64 -sIL "$hotfix_fileUrl" | grep -i Content-Length | tail -n 1 | awk '{print $2}')
        Release_size_MB=$(($size_bytes / 1024 / 1024))
        Hotfix_size=$(ReadableSizeValue $size_bytes)

    else
        Hotfix_size="No additional file"
    fi

    # echo "The CrossMix update file (v$Remote_HotfixVersion) is greater than the current version installed (v$Local_HotfixVersion)."

    echo -ne "${GREEN}DONE${NC}"

    echo -ne "\n\n\n\n" \
        "${BLUE}======= Installed Version ========${NC}\n" \
        " Version: $displayedVersion \n" \
        "${BLUE}==================================${NC}\n"
    echo -ne "\n\n" \
        "${BLUE}======== Online Version  =========${NC}\n" \
        " Version: $Remote_HotfixVersion \n" \
        " Size:    ${Hotfix_size} \n" \
        " Date:    $Remote_HotfixDate \n" \
        " URL:     $hotfix_fileUrl \n" \
        " Description:\n$Remote_HotfixDesc \n" \
        "${BLUE}==================================${NC}\n\n\n\n"

    if [ "$(echo "$Remote_HotfixVersion" | tr -d '.')" -gt "$(echo "$Local_HotfixVersion" | tr -d '.')" ]; then

        echo -e "${GREEN}Hotfix available for CrossMix v$Local_CrossMixVersion!${NC}\n\n\n"
        echo "$updatedir/.CrossMixHotfixAvailable" >"$updatedir/.CrossMixHotfixAvailable"
        return 0
    else
        echo -e "Hotfix v$Remote_HotfixVersion already applied.\n\n\n"
        rm "$updatedir/.CrossMixHotfixAvailable" 2>/dev/null
        return 1

    fi

}

######################## Custom update content (must return 0 when successful) ########################

apply_update() {

    echo -e "\n${BLUE}================== Applying Hotfix ==================${NC}\n"

    # USB Storage app update
    download_file "USB storage app fix" "https://raw.githubusercontent.com/$GITHUB_REPOSITORY/refs/heads/main/System/resources/usb_storage/launch.sh" -d "/mnt/SDCARD/System/resources/usb_storage"
    rm "/usr/trimui/apps/usb_storage/"*.png
    cp "/mnt/SDCARD/System/resources/usb_storage/"* "/usr/trimui/apps/usb_storage/"

    # Saturn ext list fix
    download_file "Saturn ext list fix" "https://raw.githubusercontent.com/$GITHUB_REPOSITORY/refs/heads/main/Emus/SATURN/config.json" -d "/mnt/SDCARD/Emus/SATURN"

    sleep 5
}

#######################################################################################################

main
