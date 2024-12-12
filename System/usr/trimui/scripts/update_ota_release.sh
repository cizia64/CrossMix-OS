#!/bin/sh
source /mnt/SDCARD/System/usr/trimui/scripts/update_common.sh

cmd=$1

# channel : stable or beta
channel=$(cat "$updatedir/ota_channel.txt" 2>/dev/null)
if [ "$channel" == "" ]; then
    channel="stable"
fi

main() {

    # enable_wifi
    check_connection
    clear

    if [ "$cmd" == "check" ]; then
        IP=$(ip route get 1 | awk '{print $NF;exit}')
        if [ "$IP" != "" ]; then
            get_release_info
            if [ $? -eq 0 ]; then
                exit 0
            fi
        fi
        exit 1
    fi

    rm /tmp/cmd_to_run.sh 2>/dev/null # avoid any resume at boot

    get_release_info
    if [ $? -eq 1 ]; then
        echo -ne "${YELLOW}"
        read -n 1 -s -r -p "Press A to exit"
        echo "no release" >/tmp/ota_release_result
        exit
        # killall -2 SimpleTerminal
    else
        touch "$updatedir/.CrossMixUpdateAvailable"
        sync
    fi
    echo -ne "${YELLOW}"
    read -n 1 -s -r -p "Press A to continue"
    echo -ne "${NC}\n"
    clear

    if [ -f "$updatedir/CrossMix-OS_v$Release_Version.zip" ] || [ -f "/mnt/SDCARD/CrossMix-OS_v$Release_Version.zip" ]; then

        if [ ! -f "$updatedir/CrossMix-OS_v$Release_Version.zip" ] && [ -f "/mnt/SDCARD/CrossMix-OS_v$Release_Version.zip" ]; then
            echo -e "File found in SDCARD root,\nmoving to $updatedir"
            mv "/mnt/SDCARD/CrossMix-OS_v$Release_Version.zip" "$updatedir/"
            sleep 4
        fi
        echo -e "\nCrossMix-OS_v$Release_Version.zip already present,\nchecking file size:"
        check_update
        if [ $? -eq 1 ]; then
            sleep 5
            download_update
        fi
    else
        sleep 5
        download_update
        check_update
    fi

    apply_update
}

get_release_info() {
    echo -ne "${PURPLE}Retrieving release information.. ${NC}"

    # Github source api url

    Release_assets_info=$(curl -k -s https://api.github.com/repos/$GITHUB_REPOSITORY/releases/latest)

    if echo "$Release_assets_info" | grep -q '"message": "Not Found"'; then
        rm "$updatedir/.CrossMixUpdateAvailable" 2>/dev/null
        echo -e "${GREEN}DONE${NC}\n\nNo update available for $channel channel\n"
        sync
        return 1
    fi

    Release_asset=$(echo "$Release_assets_info" | jq '.assets[]? | select(.name | contains("CrossMix-OS_v"))')
    Release_url=$(echo $Release_asset | jq '.browser_download_url' | tr -d '"')
    Release_FullVersion=$(echo $Release_asset | jq '.name' | tr -d "\"" | sed 's/^CrossMix-OS_v//g' | sed 's/\.zip$//g')
    Release_Version=$(echo $Release_FullVersion | sed 's/-dev.*$//g')
    Release_size=$(echo $Release_asset | jq -r '.size')
    Release_size_MB=$((Release_size / 1024 / 1024))
    Release_Date=$(echo $Release_asset | jq -r '.created_at')
    Release_info=$(echo $Release_assets_info | jq '.body')

    Local_CrossMixVersion="$(cat /mnt/SDCARD/System/usr/trimui/crossmix-version.txt)"
    Local_Version=$(echo $Local_CrossMixVersion | sed 's/-dev.*$//g')

    echo -e "${GREEN}DONE${NC}"

    echo -ne "\n\n\n\n" \
        "${BLUE}======= Installed Version ========${NC}\n" \
        " Version: $Local_CrossMixVersion \n" \
        "${BLUE}==================================${NC}\n"
    echo -ne "\n\n" \
        "${BLUE}======== Online Version  =========${NC}\n" \
        " Version: $Release_FullVersion \n" \
        " Size:    ${Release_size_MB}MB \n" \
        " Date:    $Release_Date \n" \
        " URL:     $Release_url \n" \
        "${BLUE}==================================${NC}\n\n\n\n\n"

    Local_Version=$(get_version $Local_Version)
    Remote_Version=$(get_version $Release_Version)

    if [ $Local_Version -gt $Remote_Version ] || ([ $Local_Version -eq $Remote_Version ] && [ "$Local_CrossMixVersion" = "$Release_FullVersion" ]); then
        echo -e "No new major version of CrossMix available.\n"
        rm "$updatedir/.CrossMixUpdateAvailable" 2>/dev/null
        sync
        return 1
    fi

    echo -e "${GREEN}Update available!${NC}\n"
    touch "$updatedir/.CrossMixUpdateAvailable"
    sync
    return 0
}

download_update() {
    Mychoice=$(echo -e "No\nYes" | /mnt/SDCARD/System/usr/trimui/scripts/shellect.sh -t "Download v$Release_Version (${Release_size_MB}MB) ?" -b "Press A to validate your choice.")

    if [ "$Mychoice" = "Yes" ]; then
        check_available_space "$(($Release_size_MB + 500))"
        if [ $? -eq 1 ]; then
            echo -ne "${YELLOW}"
            read -n 1 -s -r -p "Press A to exit"
            exit 3
        fi
        clear
        check_filesystem
        rm "$updatedir/CrossMix-OS_v$Release_Version.zip" 2>/dev/null
        download_file $Release_url -f "$updatedir/CrossMix-OS_v$Release_Version.zip" -t "Downloading CrossMix $Release_Version"
        if ! [ $? -eq 0 ] || ! [ -f "$updatedir/CrossMix-OS_v$Release_Version.zip" ]; then
            echo -e "${RED}CrossMix update download has failed!${NC}"
            echo -ne "${YELLOW}"
            read -n 1 -s -r -p "Press A to exit"
            echo "download failed" >/tmp/ota_release_result
            exit
            # killall -2 SimpleTerminal
        fi
        sleep 2
    else
        echo "Download canceled"
        echo "user cancel" >/tmp/ota_release_result
        exit
        # killall -2 SimpleTerminal
    fi
}

check_update() {

    Downloaded_size=$(stat -c %s "$updatedir/CrossMix-OS_v$Release_Version.zip")
    if [ "$Downloaded_size" -eq "$Release_size" ]; then
        echo -e "${GREEN}File size OK!${NC} ($Downloaded_size)"
        sleep 4
        return 0
    else
        echo -ne "\n\n${RED}Error: Wrong download size${NC} ($Downloaded_size instead of $Release_size)\n"
        return 1
    fi
}

apply_update() {
    Mychoice=$(echo -e "No\nYes" | /mnt/SDCARD/System/usr/trimui/scripts/shellect.sh -t "Apply update $Release_Version ?" -b "Press A to validate your choice.")
    clear
    if [ "$Mychoice" = "Yes" ]; then

        UpdateScript="https://raw.githubusercontent.com/cizia64/CrossMix-OS/refs/tags/v$Release_Version/System/usr/trimui/scripts/crossmix_update.sh"
        DownloadPath="/mnt/SDCARD/System/usr/trimui/scripts/crossmix_update.sh"

        download_file $UpdateScript -f "$DownloadPath" -t "Upgrading Update Script"
        if [ $? -ne 0 ] || ! [ -f "$DownloadPath" ]; then
            echo -e "${RED}Update Script upgrade has failed!${NC}"
            echo -ne "${YELLOW}"
            echo "download failed" >/tmp/ota_release_result
            read -n 1 -s -r -p "Press A to exit"
            exit
            # killall -2 SimpleTerminal
        fi

        echo -e "\n${BLUE}=============== Applying update ===============${NC}\n"

        mv "$updatedir/CrossMix-OS_v$Release_Version.zip" "/mnt/SDCARD/"
        echo "success" >/tmp/ota_release_result
        echo -ne "\n\n" \
            "${GREEN}Update $Release_Version applied.${NC}\n" \
            "Rebooting to run installation...\n"
        echo -ne "${YELLOW}"
        sync
        sleep 6
        reboot

    else
        echo "Applying update canceled"
        echo "user cancel" >/tmp/ota_release_result
        exit
        # killall -2 SimpleTerminal
    fi
}

get_version() { echo $@ | tr -d [:alpha:] | awk -F. '{ printf("%d%03d%03d%03d\n", $1,$2,$3,$4); }'; }

main
