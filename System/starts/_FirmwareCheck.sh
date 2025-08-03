#!/bin/sh

if ! read -r current_device </etc/trimui_device.txt; then
    RES=$(fbset | awk '/geometry/ {print $2 "x" $3}')
    if [ "$RES" = "1280x720" ]; then
        current_device="tsp"
    else
        current_device="brick"
    fi
    echo -n $current_device >/etc/trimui_device.txt

fi

read -r last_device </mnt/SDCARD/System/etc/last_device.txt
if [ "$current_device" != "$last_device" ]; then
    echo -n $current_device >/mnt/SDCARD/System/etc/last_device.txt
    touch /tmp/device_changed
fi

################ check min Firmware version required ################

CrossMixFWfile="/mnt/SDCARD/trimui/firmwares/MinFwVersion.txt"

if [ ! -f "$CrossMixFWfile" ]; then
    echo "Configuration file $CrossMixFWfile not found, skipping firmware check."
    exit 0
fi

Current_FW_Revision=$(grep 'DISTRIB_DESCRIPTION' /etc/openwrt_release | cut -d '.' -f 3)
Required_FW_Revision=$(sed -n '2p' "$CrossMixFWfile")

# Function to check CRC and update message
check_firmware_crc() {
    local firmware_path="$1"
    local firmware_file="$2"

    message="${message}Checking firmware integrity........"
    /mnt/SDCARD/System/usr/trimui/scripts/infoscreen2.sh -m "$message" -fs 12 -fi 0 -p top-left -fb -sp -ff "/mnt/SDCARD/Themes/CrossMix - OS/wqy-microhei.ttf" -i "/mnt/SDCARD/trimui/firmwares/FW_Screen_Wait.jpg" &

    # Extract CRC from the 7z archive
    ARCHIVE_CRC=$(/mnt/SDCARD/System/bin/7zz l "$firmware_path" -slt "$firmware_file" | grep "CRC = " | awk '{print $3}' | tr 'a-f' 'A-F')

    # Calculate CRC of the extracted file
    EXTRACTED_CRC=$(crc32 "/mnt/SDCARD/$firmware_file" | awk '{print $1}' | tr 'a-f' 'A-F')

    # Compare the CRC values
    if [ -n "$ARCHIVE_CRC" ] && [ -n "$EXTRACTED_CRC" ] && [ "$ARCHIVE_CRC" = "$EXTRACTED_CRC" ]; then
        echo "FW CRC check passed: $EXTRACTED_CRC"
        message="${message}OK"
        return 0
    else
        echo "CRC check failed: Archive CRC = $ARCHIVE_CRC, Extracted CRC = $EXTRACTED_CRC"
        message="${message}KO"
        return 1
    fi
}

diagnose() {
    pkill presenter
    sleep 0.5
    message="${message}\nChecking filesystem..."
    /mnt/SDCARD/System/usr/trimui/scripts/infoscreen2.sh -m "$message" -fs 12 -fi 0 -p top-left -fb -sp -ff "/mnt/SDCARD/Themes/CrossMix - OS/wqy-microhei.ttf" -i "/mnt/SDCARD/trimui/firmwares/FW_Screen_Wait.jpg" &
    check_filesystem
    FW_Size=$(/mnt/SDCARD/System/bin/7zz l "$FIRMWARE_PATH" -slt "$FIRMWARE_FILE" | awk ' /^Path = / {found=1; next}  found && /^Size = / { print $3; exit }
')

    FW_Size_MB=$(($FW_Size / 1024 / 1024))
    if ! check_available_space "$(($FW_Size_MB + 100))"; then
        echo "Insufficient space available."
        message="${message}done\nInsufficient space available.\nYou need at least $(($FW_Size_MB + 100)) MB free on SD Card."
        sleep 1.5
        pkill presenter
        sleep 0.5
        /mnt/SDCARD/System/usr/trimui/scripts/infoscreen2.sh -m "$message" -fs 12 -fi 0 -p top-left -fb -ff "/mnt/SDCARD/Themes/CrossMix - OS/wqy-microhei.ttf" -i "/mnt/SDCARD/trimui/firmwares/FW_Screen_Fail.jpg" -k rout A "Exit"
    else
        echo "Sufficient space available."
        message="${message}done\nSufficient space available.\nYou have enough space to update firmware."
        sleep 1.5
        pkill presenter
        sleep 0.5
        /mnt/SDCARD/System/usr/trimui/scripts/infoscreen2.sh -m "$message" -fs 12 -fi 0 -p top-left -fb -ff "/mnt/SDCARD/Themes/CrossMix - OS/wqy-microhei.ttf" -i "/mnt/SDCARD/trimui/firmwares/FW_Screen_Fail.jpg" -k rout A "Exit"
    fi
}

echo "Current FW Revision: $Current_FW_Revision"
echo "Required FW Revision: $Required_FW_Revision"

if [ -z "$Current_FW_Revision" ] || [ -z "$Required_FW_Revision" ]; then

    echo "Firmware check not possible."

else

    if [ "$Current_FW_Revision" -lt "$Required_FW_Revision" ]; then

        source /mnt/SDCARD/System/usr/trimui/scripts/common_functions.sh

        pgrep -f trimui_inputd >/dev/null || { cd "/mnt/SDCARD/trimui/app" && ./trimui_inputd & } # we need input

        CrossMix_version=$(cat /mnt/SDCARD/System/usr/trimui/crossmix-version.txt)
        Current_FW_Version="$(cat /etc/version)"
        Required_FW_Version=$(sed -n '1p' "$CrossMixFWfile")

        echo "Current firmware ($Current_FW_Version - $Current_FW_Revision) must be updated to $Required_FW_Version - $Required_FW_Revision to support CrossMix OS v$CrossMix_version."

        # Install new busybox from PortMaster, credits : https://github.com/kloptops/TRIMUI_EX

        Current_busybox_crc=$(crc32 "/bin/busybox" | awk '{print $1}')
        target_busybox_crc=$(crc32 "/mnt/SDCARD/System/usr/trimui/scripts/busybox" | awk '{print $1}')

        if [ "$Current_busybox_crc" != "$target_busybox_crc" ]; then

            # make some place
            rm -rf /usr/trimui/apps/zformatter_fat32/
            rm -rf /usr/trimui/res/sound/bgm2.mp3
            swapoff -a
            rm -rf /swapfile
            cp "/mnt/SDCARD/trimui/res/skin/bg.png" "/usr/trimui/res/skin/"

            cp -vf /bin/busybox /mnt/SDCARD/System/bin/busybox.bak
            /mnt/SDCARD/System/bin/rsync /mnt/SDCARD/System/usr/trimui/scripts/busybox /bin/busybox
            ln -vs "/bin/busybox" "/bin/bash"

            # Create missing busybox commands
            for cmd in $(busybox --list); do
                # Skip if command already exists or if it's not suitable for linking
                if [ -e "/bin/$cmd" ] || [ -e "/usr/bin/$cmd" ] || [ "$cmd" = "sh" ]; then
                    continue
                fi

                # Create a symbolic link
                ln -vs "/bin/busybox" "/usr/bin/$cmd"
            done

            # Fix weird libSDL location
            for libname in /usr/trimui/lib/libSDL*; do
                linkname="/usr/lib/$(basename "$libname")"
                if [ -e "$linkname" ]; then
                    continue
                fi
                ln -vs "$libname" "$linkname"
            done
        fi

        sync

        FIRMWARE_PATH="/mnt/SDCARD/trimui/firmwares/firmware_${current_device}_v${Required_FW_Version}_${Required_FW_Revision}.7z.001"
        FIRMWARE_FILE="trimui_tg5040.awimg"
        message="Current   FW version: $Current_FW_Version - $Current_FW_Revision\nRequired FW version: $Required_FW_Version - $Required_FW_Revision\n \n \n"
        crc_verified=false

        if [ ! -f "$FIRMWARE_PATH" ]; then
            echo "Firmware file not found: $FIRMWARE_PATH"
            /mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -i bg-exit.png -m "Firmware file not found, canceling update." -k A
            exit 1
        fi

        if [ -f "/mnt/SDCARD/$FIRMWARE_FILE" ]; then
            echo "Firmware file already exists, checking CRC..."

            message="${message}A firmware file is already present.\n"

            if check_firmware_crc "$FIRMWARE_PATH" "$FIRMWARE_FILE"; then
                echo "CRC check on existing file is OK. Skipping extraction."
                crc_verified=true
            else
                echo "CRC check on existing file failed. Re-extracting."
                rm -f "/mnt/SDCARD/$FIRMWARE_FILE"
            fi
        fi

        if [ "$crc_verified" = false ]; then
            message="${message}\n \n \nExtracting new firmware v$Required_FW_Version..."
            pkill presenter
            sleep 0.5
            /mnt/SDCARD/System/usr/trimui/scripts/infoscreen2.sh -m "$message" -fs 12 -fi 0 -p top-left -fb -sp -ff "/mnt/SDCARD/Themes/CrossMix - OS/wqy-microhei.ttf" -i "/mnt/SDCARD/trimui/firmwares/FW_Screen_Wait.jpg" &

            /mnt/SDCARD/System/usr/trimui/scripts/cpufreq.sh ondemand 3 7
            if ! /mnt/SDCARD/System/bin/7zz x "$FIRMWARE_PATH" -o"/mnt/SDCARD" -y; then
                echo "Failed to extract firmware"
                pkill presenter
                sleep 0.5
                message="${message}\nFirmware extraction failed, canceling update.\n \nPress X to diagnose."
                /mnt/SDCARD/System/usr/trimui/scripts/infoscreen2.sh -m "$message" -fs 12 -fi 0 -p top-left -fb -ff "/mnt/SDCARD/Themes/CrossMix - OS/wqy-microhei.ttf" -i "/mnt/SDCARD/trimui/firmwares/FW_Screen_Fail.jpg" -k rout A "" -k rout X ""
                rm "/mnt/SDCARD/$FIRMWARE_FILE"
                diagnose
                exit 1
            fi
            message="${message}OK\n"
            pkill presenter
            sleep 0.5
            sync

            if check_firmware_crc "$FIRMWARE_PATH" "$FIRMWARE_FILE"; then
                crc_verified=true
            else
                message="${message}\nFirmware CRC check has failed, canceling update.\nPress X to diagnose."
                pkill presenter
                sleep 0.5
                /mnt/SDCARD/System/usr/trimui/scripts/infoscreen2.sh -m "$message" -fs 12 -fi 0 -p top-left -fb -ff "/mnt/SDCARD/Themes/CrossMix - OS/wqy-microhei.ttf" -i "/mnt/SDCARD/trimui/firmwares/FW_Screen_Fail.jpg" -k rout A "" -k rout X ""
                rm "/mnt/SDCARD/$FIRMWARE_FILE"
                diagnose
                exit 1
            fi
        fi

        if [ "$crc_verified" = true ]; then

            pkill presenter
            sleep 0.5

            message="${message}\nReady for update!\n \nPlease read instructions at the right\nto launch your firmware upgrade."

            /mnt/SDCARD/System/usr/trimui/scripts/infoscreen2.sh -m "$message" -fs 12 -fi 0 -p top-left -fb -ff "/mnt/SDCARD/Themes/CrossMix - OS/wqy-microhei.ttf" -i "/mnt/SDCARD/trimui/firmwares/FW_Screen_Ready.jpg" -k rout A "" -k rin B ""

            if [ "$?" -eq 14 ]; then # A has been pressed
                sleep 1
                pkill presenter
                sync
                /usr/trimui/bin/kill_apps.sh
                sleep 30
                poweroff
                sleep 30
                exit
            else
                pkill presenter
                exit
            fi

        fi

    else
        echo "Firmware version $Current_FW_Revision OK."
        rm -f "/mnt/SDCARD/trimui_tg5040.awimg"

    fi
fi

################ check if a CrossMix-OS update is available ################

# Set PATH and library path
PATH="/mnt/SDCARD/System/bin:/mnt/SDCARD/System/usr/trimui/scripts/:$PATH"
export LD_LIBRARY_PATH="/mnt/SDCARD/System/lib:/usr/trimui/lib:$LD_LIBRARY_PATH"

# Find the update file
UPDATE_FILE=$(find /mnt/SDCARD -maxdepth 1 -name "CrossMix-OS_v*.zip" -print -quit)

if [ -n "$UPDATE_FILE" ]; then
    /usr/trimui/bin/trimui_inputd & # we need input
    echo "CrossMix-OS install file found: $UPDATE_FILE"
    initial_version=$(cat /mnt/SDCARD/System/usr/trimui/crossmix-version.txt)
    update_version=$(echo "$UPDATE_FILE" | awk -F'_v|\.zip' '{print $2}')

    # Compare the versions
    if [ "$(echo "$update_version" | tr -d '.')" -gt "$(echo "$initial_version" | tr -d '.')" ]; then
        echo "The CrossMix update file (v$update_version) is greater than the current version installed ($initial_version)."

        minspace=$((20 * 1024))
        rootfs_space=$(df / | awk 'NR==2 {print $4}')
        if [ "$rootfs_space" -lt "$minspace" ]; then
            echo "Error: Available space on internal storage is less than 20 MB"
            infoscreen.sh -m "CrossMix-OS update v$update_version found. Not enough space on internal storage to update." -k "A B START MENU" -fs 30
            exit 1
        else
            echo "Available space on / is sufficient: ${rootfs_space} KB"
        fi

        if [ ! -f "/mnt/SDCARD/trimui/res/crossmix-os/bg-info.png" ] ||
            [ ! -f "/mnt/SDCARD/System/bin/sdl2imgshow" ] ||
            [ ! -f "/mnt/SDCARD/System/usr/trimui/scripts/crossmix_update.sh" ] ||
            [ ! -f "/mnt/SDCARD/System/usr/trimui/scripts/getkey.sh" ] ||
            [ ! -f "/mnt/SDCARD/System/usr/trimui/scripts/common_launcher.sh" ] ||
            [ ! -f "/mnt/SDCARD/System/usr/trimui/scripts/evtest" ]; then
            echo "One or more required files are missing."
            /mnt/SDCARD/System/bin/7zz -aoa x "$UPDATE_FILE" \
                -o"/mnt/SDCARD" \
                -i"!System/bin/*" \
                -i"!System/lib/*" \
                -i"!System/resources/*" \
                -i"!System/usr/trimui/scripts/*" \
                -i"!trimui/res/crossmix-os/*"
            sync
        fi

        button=$(infoscreen.sh -m "CrossMix-OS update v$update_version found. Press A to install, B to cancel." -k "A B")
        if [ "$button" = "A" ]; then
            /mnt/SDCARD/System/bin/7zz e "$UPDATE_FILE" "System/usr/trimui/scripts/crossmix_update.sh" -o/tmp -y
            chmod a+x "/tmp/crossmix_update.sh"
            cp /mnt/SDCARD/System/bin/text_viewer /tmp
            infoscreen.sh -m "Updating CrossMix to v$update_version" -t 1
            pkill -9 preload.sh
            pkill -9 runtrimui.sh
            /tmp/text_viewer -s "/tmp/crossmix_update.sh" -f 25 -t "                            CrossMix-OS Update v$update_version                                      "
        fi
    else
        echo "The CrossMix update version ($update_version) is not greater than the current version ($initial_version)."
    fi
else
    echo "No CrossMix update file found."
fi
