#!/bin/sh

# Export necessary environment variables
export PATH="/mnt/SDCARD/System/bin:$PATH"
export LD_LIBRARY_PATH="/mnt/SDCARD/System/lib:/usr/trimui/lib:$LD_LIBRARY_PATH"

# Update theme pack in CrossMix configuration
if [ -n "$packname" ] && [ -n "$style" ]; then
    jq --arg packname "$packname" --arg style "$style" '.["THEME PACK"] = $packname | .["CROSSMIX STYLE"] = $style' /mnt/SDCARD/System/etc/crossmix.json >/tmp/crossmix.json && mv /tmp/crossmix.json /mnt/SDCARD/System/etc/crossmix.json
else
    echo "packname and style variables are not defined."
    /mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "packname and style variables are not defined." -c red -t 4
    exit
fi

# Apply theme
if [ -n "$theme" ]; then
    if [ -d "/mnt/SDCARD/Themes/${theme}" ]; then
        /mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "Applying \"${theme}\" theme." -t 1
        /usr/trimui/bin/systemval "theme" "/mnt/SDCARD/Themes/${theme}/"
    else
        echo "Theme directory Themes/${theme} does not exist."
        /mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "\"${theme}\" theme directory does not exist !!" -c red -t 3
    fi
fi

# Apply boot logo
if [ -n "$bootlogo" ]; then
    read -r Current_device </etc/trimui_device.txt

    if [ "$Current_device" = "tsp" ]; then
        src_dir="/mnt/SDCARD/Apps/BootLogo/Images_1280x720/"
    else
        src_dir="/mnt/SDCARD/Apps/BootLogo/Images_1024x768/"
    fi

    if [ -f "$src_dir/$bootlogo" ]; then
        /mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -i "$src_dir/$bootlogo" -m "Flashing logo..." -fs 100 -c green -t 0.5
        "/mnt/SDCARD/Emus/_BootLogo/launch.sh" "$src_dir/$bootlogo"
    else
        echo "BootLogo Apps/BootLogo/Images/$bootlogo does not exist."
        /mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "\"Apps/BootLogo/Images/$bootlogo\" does not exist !!" -fs 27 -c red -t 3
    fi
fi

# Apply emulator icon collection
if [ -n "$emuicons" ]; then
    if [ -f "/mnt/SDCARD/Apps/SystemTools/Menu/ADVANCED SETTINGS##EMULATOR ICONS (value)/${emuicons}.sh" ]; then
        "/mnt/SDCARD/Apps/SystemTools/Menu/ADVANCED SETTINGS##EMULATOR ICONS (value)/${emuicons}.sh"
    else
        echo "Icon script Apps/SystemTools/Menu/ADVANCED SETTINGS##EMULATOR ICONS (value)/${emuicons}.sh does not exist."
        /mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "\"Apps/SystemTools/Menu/ADVANCED SETTINGS##EMULATOR ICONS (value)/${emuicons}.sh\" does not exist !!" -fs 22 -c red -t 3
    fi
fi

# Apply app icons collection
if [ -n "$appicons" ]; then
    if [ -f "/mnt/SDCARD/Apps/SystemTools/Menu/ADVANCED SETTINGS##APP ICONS (value)/${appicons}.sh" ]; then
        "/mnt/SDCARD/Apps/SystemTools/Menu/ADVANCED SETTINGS##APP ICONS (value)/${appicons}.sh"
    else
        echo "Icon script Apps/SystemTools/Menu/ADVANCED SETTINGS##APP ICONS (value)/${appicons}.sh does not exist."
        /mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "\"Apps/SystemTools/Menu/ADVANCED SETTINGS##APP ICONS (value)/${appicons}.sh\" does not exist !!" -fs 22 -c red -t 3
    fi
fi

# Apply background collection
if [ -n "$background" ]; then
    if [ -f "/mnt/SDCARD/Apps/SystemTools/Menu/ADVANCED SETTINGS##BACKGROUNDS (value)/${background}.sh" ]; then
        "/mnt/SDCARD/Apps/SystemTools/Menu/ADVANCED SETTINGS##BACKGROUNDS (value)/${background}.sh"
    else
        echo "Background script Apps/SystemTools/Menu/ADVANCED SETTINGS##BACKGROUNDS (value)/${background}.sh does not exist."
        /mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "\"Apps/SystemTools/Menu/ADVANCED SETTINGS##BACKGROUNDS (value)/${background}.sh\" does not exist !!" -fs 22 -c red -t 3
    fi
fi

# Apply emulator labels
if [ -n "$emulabels" ]; then
    if [ -f "/mnt/SDCARD/Apps/SystemTools/Menu/ADVANCED SETTINGS##EMULATOR LABELS (value)/${emulabels}.sh" ]; then
        "/mnt/SDCARD/Apps/SystemTools/Menu/ADVANCED SETTINGS##EMULATOR LABELS (value)/${emulabels}.sh"
    else
        echo "Background script \"Apps/SystemTools/Menu/ADVANCED SETTINGS##EMULATOR LABELS (value)/${emulabels}.sh\" does not exist."
        /mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "\"Apps/SystemTools/Menu/ADVANCED SETTINGS##EMULATOR LABELS (value)/${emulabels}.sh\" does not exist !!" -fs 22 -c red -t 3
    fi
fi

# Update autorun configuration with the appropriate icon
if [ -n "$packname" ]; then
    if [ -f "/mnt/SDCARD/trimui/res/crossmix-os/theme_$packname/icon.ico" ]; then
        /mnt/SDCARD/System/usr/trimui/scripts/set_ra_cfg.sh /mnt/SDCARD/autorun.inf icon "trimui/res/crossmix-os/theme_$packname/icon.ico"
    else
        /mnt/SDCARD/System/usr/trimui/scripts/set_ra_cfg.sh /mnt/SDCARD/autorun.inf icon "trimui/res/crossmix-os/icon.ico"
    fi
fi

# Sync filesystem
sync

#---------------------------------------------------------------------------

/mnt/SDCARD/System/usr/trimui/scripts/mainui_state_update.sh "THEME PACK" "$packname"

/mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "\"$packname\" applied" -t3
