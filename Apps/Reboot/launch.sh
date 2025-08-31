#!/bin/sh

if [[ $EUID -ne 0 ]]; then
   exit 1
fi

Current_Theme=$(/usr/trimui/bin/systemval theme)
Shutdown_Screen="$Current_Theme/skin/shutdown.png"
if [ ! -f "$Shutdown_Screen" ]; then
   if [ -f "$Current_Theme/skin/bg.png" ]; then
      Shutdown_Screen="$Current_Theme/skin/bg.png"
   else
      Shutdown_Screen="/mnt/SDCARD/trimui/res/crossmix-os/bg-info.png"
   fi
   Shutdown_Text="Rebooting..."
else
   Shutdown_Text=" "
fi

/mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -i "$Shutdown_Screen" -m "$Shutdown_Text" -fs 100

sync
# Short Vibration
echo -n 1 >/sys/class/gpio/gpio227/value
sleep 0.1
echo -n 0 >/sys/class/gpio/gpio227/value
sleep 0.3

/mnt/SDCARD/System/bin/shutdown -r
