#!/bin/sh
export LD_LIBRARY_PATH="/mnt/SDCARD/System/lib:/usr/trimui/lib:$LD_LIBRARY_PATH"
read -r current_device </etc/trimui_device.txt
Current_Theme=$(/usr/trimui/bin/systemval theme)
Current_bg="$Current_Theme/skin/bg.png"
if [ ! -f "$Current_bg" ]; then
    Current_bg="/mnt/SDCARD/trimui/res/skin/transparent.png"
fi

################ CrossMix-OS Version Splashscreen ################
read -r version </mnt/SDCARD/System/usr/trimui/crossmix-version.txt
/mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -i "$Current_bg" -m "CrossMix OS v$version" &

################ CrossMix-OS internal storage Customization ################
read -r FW_patched_version </usr/trimui/crossmix-version.txt

if [ "$version" != "$FW_patched_version" ]; then

    if [ -f "/usr/trimui/crossmix-version.txt" ]; then
        CrossMix_Update=1
    else
        CrossMix_Update=0 # CrossMix installation on new device or after firmware udpdate
    fi

    /mnt/SDCARD/System/usr/trimui/scripts/inputd_switcher.sh

    # Removing duplicated app
    rm -rf /usr/trimui/apps/zformatter_fat32/

    # making some place in root fs
    rm -rf /usr/trimui/res/sound/bgm2.mp3
    swapoff -a
    rm -rf /swapfile
    cp "/mnt/SDCARD/trimui/res/skin/bg.png" "/usr/trimui/res/skin/"

    # USB Storage app update
    rm "/usr/trimui/apps/usb_storage/"*.png
    cp "/mnt/SDCARD/System/resources/usb_storage/"* "/usr/trimui/apps/usb_storage/"

    # Disable Stock Music app
    mv /usr/trimui/apps/musicplayer/config.json /usr/trimui/apps/musicplayer/config_disabled.json

    # Disable Stock Reader app
    mv /usr/trimui/apps/bookreader/config.json /usr/trimui/apps/bookreader/config_disabled.json

    case "$current_device" in
    tsp) ;;
    tsps)
        # fix GL symbolic links for mali drivers
        cd /usr/lib
        ln -s libmali.so libIMGegl.so
        ln -s libmali.so libGLES_CM.so
        ln -s libmali.so libGLESv1_CM.so
        ln -s libmali.so libGLESv2.so
        ln -s libmali.so libglslcompiler.so
        ln -s libmali.so libsrv_um.so
        ln -s libmali.so libusc.so
        ;;
    brick) ;;
    *) ;;
    esac

    # add language files
    if [ ! -e "/usr/trimui/res/skin/pl.lang" ]; then
        cp "/mnt/SDCARD/trimui/res/lang/"*.lang "/usr/trimui/res/lang/"
        cp "/mnt/SDCARD/trimui/res/lang/"*.short "/usr/trimui/res/lang/"
        cp "/mnt/SDCARD/trimui/res/lang/"*.png "/usr/trimui/res/skin/"
    fi

    # patching language files for MainUI device specific texts
    source /mnt/SDCARD/System/etc/ex_config # required to initialize python3 environment for lang_patches.sh
    /mnt/SDCARD/System/usr/trimui/scripts/lang_patches.sh "$current_device"

    # custom shutdown script for "Resume at Boot"
    cp "/mnt/SDCARD/System/usr/trimui/bin/kill_apps.sh" "/usr/trimui/bin/kill_apps.sh"
    chmod a+x "/usr/trimui/bin/kill_apps.sh"

    # custom sshd initd script & disabled by default
    cp "/mnt/SDCARD/trimui/etc/init.d/sshd" /etc/init.d/sshd
    chmod a+x /etc/init.d/sshd
    /etc/init.d/sshd disable

    # fix retroarch path for PortMaster
    cp "/mnt/SDCARD/System/usr/trimui/bin/retroarch" "/usr/bin/retroarch"
    chmod a+x "/usr/bin/retroarch"

    # custom shutdown script, will be called by MainUI
    # cp "/mnt/SDCARD/System/bin/shutdown" "/usr/bin/poweroff"
    # chmod a+x "/usr/bin/poweroff"

    # modifying default theme to impact all other themes (Better game image background)
    cp "/mnt/SDCARD/trimui/res/skin/ic-game-580.png" "/usr/trimui/res/skin/ic-game-580.png"

    # Fnkey app modifications
    CrossMixSourceDir="/mnt/SDCARD/System/usr/trimui/res/apps/fn_editor"
    FWappDir="/usr/trimui/apps/fn_editor"
    FWsceneDir="/usr/trimui/scene"
    fnkeysDir="/usr/trimui/fnkeys"

    mkdir -p "$FWappDir" "$FWsceneDir"

    copy_file() {
        src=$1
        dest=$2

        if cp "$src" "$dest"; then
            chmod a+x "$dest"
            echo "$(basename "$src") -> $dest"
        fi
    }

    # Always install applications
    for src in "$CrossMixSourceDir"/*; do
        filename=$(basename "$src")

        copy_file "$src" "$FWappDir/$filename"

        if [ "$CrossMix_Update" = "1" ]; then
            [ -f "$FWsceneDir/$filename" ] &&
                copy_file "$src" "$FWsceneDir/$filename"

            [ -f "$fnkeysDir/$filename" ] &&
                copy_file "$src" "$fnkeysDir/$filename"
        fi
    done

    # Fresh install: install default FN functions
    if [ "$CrossMix_Update" != "1" ]; then
        case "$current_device" in
        tsp | tsps)
            copy_file "$CrossMixSourceDir/com.trimui.cpuperformance.sh" "$FWsceneDir/com.trimui.cpuperformance.sh"
            ;;

        brick | brickpro)
            copy_file "$CrossMixSourceDir/com.crossmix.nightmode.sh" "$FWsceneDir/com.crossmix.nightmode.sh"
            copy_file "$FWappDir/com.trimui.ledc.sh" "$FWsceneDir/com.trimui.ledc.sh"
            copy_file "$CrossMixSourceDir/com.trimui.switch.cpufreq.sh" "$fnkeysDir/com.trimui.switch.cpufreq.sh"
            copy_file "$CrossMixSourceDir/com.trimui.switch.backlight.sh" "$fnkeysDir/com.trimui.switch.backlight.sh"
            copy_file "$CrossMixSourceDir/f1key.json" "$fnkeysDir/f1key.json"
            copy_file "$CrossMixSourceDir/f2key.json" "$fnkeysDir/f2key.json"
            ;;
        esac
    fi

    # Upgrade the stock OSD
    cp -a /mnt/SDCARD/System/usr/trimui/res/osd/. /usr/trimui/osd/
    find /usr/trimui/osd/ -type f -name "*" -exec chmod a+x {} \;

    # Customize SSH sessions
    if ! grep -q "SSH_CONNECTION" /etc/profile; then
        printf '\n\n[ -n "$SSH_CONNECTION" ] || [ -n "$SSH_CLIENT" ] && . /mnt/SDCARD/System/usr/trimui/scripts/ssh_profile.sh\n' >>/etc/profile
    fi

    if [ "$CrossMix_Update" = "0" ]; then # This is a fresh internal firmware
        if -f "/mnt/SDCARD/trimui/firmwares/Last_Automatic_Backup.txt"; then
            Last_Automatic_Backup=$(cat /mnt/SDCARD/trimui/firmwares/Last_Automatic_Backup.txt)
            if [ -f "/mnt/SDCARD/System/backups/firmware_settings/$current_device/$Last_Automatic_Backup" ]; then
                # We have a backup for this device, restoring firmware settings
                "/mnt/SDCARD/Apps/SystemTools/Menu/TOOLS/FW Settings Save-Load.sh" --restore "/mnt/SDCARD/System/backups/firmware_settings/$current_device/$Last_Automatic_Backup" all
            fi
        else
            # No backup, apply default CrossMix theme, sound volume, and grid view
            if [ ! -f /mnt/UDISK/system.json ]; then
                cp /mnt/SDCARD/System/usr/trimui/scripts/MainUI_default_system.json /mnt/UDISK/system.json
            else
                /usr/trimui/bin/systemval theme "/mnt/SDCARD/Themes/CrossMix - OS/"
                /usr/trimui/bin/systemval menustylel1 1
                /usr/trimui/bin/systemval bgmvol 10
                /usr/trimui/bin/systemval picturesize 100
            fi
        fi
    fi

    if [ "$Current_Theme" = "../res/" ]; then
        /usr/trimui/bin/systemval theme "/mnt/SDCARD/Themes/CrossMix - OS/"
    fi

    # hide netplay tab in MainUI
    /usr/trimui/bin/systemval netplaytab 0

    # Fix app icons
    "/mnt/SDCARD/Apps/SystemTools//Menu/ADVANCED SETTINGS##APP ICONS (value)/Default.sh"

    # modifying performance mode for Moonlight
    if ! grep -qF "performance" "/usr/trimui/apps/moonlight/launch.sh"; then
        sed -i 's|^\./moonlightui|echo performance > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor\necho 1608000 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq\n\./moonlightui|' /usr/trimui/apps/moonlight/launch.sh
    fi

    # we set the customization flag
    rm "/usr/trimui/fw_mod_done"
    echo $version >/usr/trimui/crossmix-version.txt

    ################ CrossMix-OS SD card Customization ################

    # Sorting Themes Alphabetically
    "/mnt/SDCARD/Apps/SystemTools/Menu/THEME/Sort Themes Alphabetically.sh" -s

    # Game tab by default
    if [ "$CrossMix_Update" = "0" ]; then
        "/mnt/SDCARD/Apps/SystemTools/Menu/USER INTERFACE##START TAB (value)/Tab 4.sh" -s
    fi

    # Displaying only Emulators with roms
    /mnt/SDCARD/Apps/EmuCleaner/launch.sh -s

    ################ Flash boot logo ################
    if [ "$CrossMix_Update" = "0" ]; then
        case "$current_device" in
        tsp | tsps)
            src_dir="/mnt/SDCARD/Apps/BootLogo/Images_1280x720"
            ;;
        brick | brickpro)
            src_dir="/mnt/SDCARD/Apps/BootLogo/Images_1024x768"
            ;;
        *)
            src_dir="/mnt/SDCARD/Apps/BootLogo/Images_1280x720"
            ;;
        esac

        /mnt/SDCARD/Emus/_BootLogo/launch.sh "$src_dir/- CrossMix-OS.bmp"
    fi

    sync

fi


######################### CrossMix-OS at each boot #########################

# override empty password on firmware >= v1.1.1
echo "root:tina" | chpasswd

# Apply current led configuration
/mnt/SDCARD/System/etc/led_config.sh &

######################### Device Type customization #########################

if [ -f "/tmp/device_changed" ]; then

    # copy of the most up-to-date version of retroarch for this device
    files=$(ls /mnt/SDCARD/RetroArch/ra64.trimui_${current_device}_*.bin 2>/dev/null)
    latest_file=$(echo "$files" | sort -V | tail -n 1)
    cp "$latest_file" "/mnt/SDCARD/RetroArch/ra64.trimui"

    # OSD customization
    cp /mnt/SDCARD/System/usr/trimui/res/osd/osdlayout_${current_device}.json /usr/trimui/osd/osdlayout.json
    # OSD binaries
    chmod a+x /usr/trimui/osd/trimui_osdd
    cp /mnt/SDCARD/System/usr/trimui/osd/cpuinfo_osdd_${current_device}   /mnt/SDCARD/System/usr/trimui/osd/cpuinfo_osdd
    cp /mnt/SDCARD/System/usr/trimui/osd/nightmode_osdd_${current_device} /mnt/SDCARD/System/usr/trimui/osd/nightmode_osdd

    sync

    # Change Avahi DNS name
    sed -i "s/^host-name=.*/host-name=$current_device/" /mnt/SDCARD/System/etc/avahi/avahi-daemon.conf

fi
