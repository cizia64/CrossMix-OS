#!/bin/sh

PATH="/mnt/SDCARD/System/bin:$PATH"

# Update theme pack in CrossMix configuration
jq --arg packname "$packname" --arg style "$style" '.["THEME PACK"] = $packname | .["CROSSMIX STYLE"] = $style' /mnt/SDCARD/System/etc/crossmix.json > /tmp/crossmix.json && mv /tmp/crossmix.json /mnt/SDCARD/System/etc/crossmix.json

# Apply theme
if [ -d "/mnt/SDCARD/Themes/${theme}" ]; then
	/mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "Applying \"${theme}\" theme." -t 1
    /usr/trimui/bin/systemval "theme" "/mnt/SDCARD/Themes/${theme}/"
else
    echo "Theme directory Themes/${theme} does not exist."
	/mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "\"${theme}\" theme directory does not exist !!" -c red -t 3
fi

# Apply boot logo
if [ -f "/mnt/SDCARD/Apps/BootLogo/Images/$bootlogo" ]; then
    /mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -i "/mnt/SDCARD/Apps/BootLogo/Images/$bootlogo" -m "Flashing logo..." -fs 100 -t 2.5 -c green
	"/mnt/SDCARD/Emus/_BootLogo/launch.sh" "/mnt/SDCARD/Apps/BootLogo/Images/$bootlogo"
else
    echo "BootLogo Apps/BootLogo/Images/$bootlogo does not exist."
	/mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "\"Apps/BootLogo/Images/$bootlogo\" does not exist !!" -fs 27 -c red -t 3
fi

# Apply icon collection
if [ -f "/mnt/SDCARD/Apps/SystemTools/Menu/ADVANCED SETTINGS##ICONS (value)/${icon}.sh" ]; then
    "/mnt/SDCARD/Apps/SystemTools/Menu/ADVANCED SETTINGS##ICONS (value)/${icon}.sh"
else
    echo "Icon script Apps/SystemTools/Menu/ADVANCED SETTINGS##ICONS (value)/${icon}.sh does not exist."
	/mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "\"Apps/SystemTools/Menu/ADVANCED SETTINGS##ICONS (value)/${icon}.sh\" does not exist !!" -fs 27 -c red -t 3
fi

# Apply background collection
if [ -f "/mnt/SDCARD/Apps/SystemTools/Menu/ADVANCED SETTINGS##BACKGROUNDS (value)/${background}.sh" ]; then
    "/mnt/SDCARD/Apps/SystemTools/Menu/ADVANCED SETTINGS##BACKGROUNDS (value)/${background}.sh"
else
    echo "Background script Apps/SystemTools/Menu/ADVANCED SETTINGS##BACKGROUNDS (value)/${background}.sh does not exist."
	/mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "\"Apps/SystemTools/Menu/ADVANCED SETTINGS##BACKGROUNDS (value)/${background}.sh\" does not exist !!" -fs 27 -c red -t 3
fi

# Update autorun configuration with the appropriate icon
if [ -f "/mnt/SDCARD/trimui/res/crossmix-os/theme_$packname/icon.ico" ]; then
    /mnt/SDCARD/System/usr/trimui/scripts/set_ra_cfg.sh /mnt/SDCARD/autorun.inf icon "trimui/res/crossmix-os/theme_$packname/icon.ico"
else
    /mnt/SDCARD/System/usr/trimui/scripts/set_ra_cfg.sh /mnt/SDCARD/autorun.inf icon "trimui/res/crossmix-os/icon.ico"
fi

# Sync filesystem
sync