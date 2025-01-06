#!/bin/sh

kill_childs() {
  pids="$*"

  set -- $(pgrep -P "$@" 2>/dev/null)
  if [ -n "$*" ]; then
    kill_childs "$@"
  fi

  echo "Killing PIDs: $pids"
  kill $pids 2>/dev/null
  for pid in $pids; do
    while kill -0 "$pid" 2>/dev/null; do
      sleep 0.1
    done
  done
}

#pid=`ps | grep cmd_to_run | grep -v grep | sed 's/[ ]\+/ /g' | cut -d' ' -f1`

/mnt/SDCARD/System/usr/trimui/scripts/button_state.sh MENU
exit_code=$?
if [ $exit_code -eq 10 ]; then # we don't resume if menu is pressed during boot
   echo "=== Button MENU pressed ==="
   /mnt/SDCARD/System/usr/trimui/scripts/cmd_to_run_killer.sh &
   # Short Vibration
   echo -n 1 >/sys/class/gpio/gpio227/value
   sleep 0.1
   echo -n 0 >/sys/class/gpio/gpio227/value
   sleep 0.2
   # 3 fast red blinking
   echo 1 >/sys/class/led_anim/effect_enable
   echo "FF0000" >/sys/class/led_anim/effect_rgb_hex_lr
   echo 3 >/sys/class/led_anim/effect_cycles_lr
   echo 50 >/sys/class/led_anim/effect_duration_lr
   echo 5 >/sys/class/led_anim/effect_lr
   exit
fi

set_led_color() {
   r=$1
   g=$2
   b=$3
   valstr=$(printf "%02X%02X%02X" $r $g $b)
   echo "$valstr $valstr $valstr $valstr $valstr $valstr $valstr $valstr $valstr $valstr $valstr $valstr $valstr $valstr $valstr $valstr " \
      "$valstr $valstr $valstr $valstr $valstr $valstr $valstr" >/sys/class/led_anim/frame_hex
}
set_led_color 255 255 0 # Yellow

# Short Vibration
echo -n 1 >/sys/class/gpio/gpio227/value
sleep 0.1
echo -n 0 >/sys/class/gpio/gpio227/value
sleep 0.2

Current_Theme=$(/usr/trimui/bin/systemval theme)
Shutdown_Screen="$Current_Theme/skin/shutdown.png"
if [ ! -f "$Shutdown_Screen" ]; then
   if [ -f "$Current_Theme/skin/bg.png" ]; then
      Shutdown_Screen="$Current_Theme/skin/bg.png"
   else
      Shutdown_Screen="/mnt/SDCARD/trimui/res/crossmix-os/bg-info.png"
   fi
   Shutdown_Text="Shutting down..."
else
   Shutdown_Text=" "
fi

/mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -i "$Shutdown_Screen" -m "$Shutdown_Text" -fs 100

echo 1 >/sys/class/led_anim/effect_enable
echo "FF0000" >/sys/class/led_anim/effect_rgb_hex_lr
echo 10 >/sys/class/led_anim/effect_cycles_lr
echo 500 >/sys/class/led_anim/effect_duration_lr
echo 1 >/sys/class/led_anim/effect_lr

cp /tmp/cmd_to_run.sh /mnt/SDCARD/trimui/app/
sync

pkill -9 preload.sh # avoid to remove /mnt/SDCARD/trimui/app/cmd_to_run.sh when we shutdown directly from a resume
pkill -9 runtrimui.sh

kill_childs "$1"

aplay /mnt/SDCARD/trimui/res/sound/PowerOff.wav -d 1

sync
/mnt/SDCARD/System/bin/shutdown

sleep 8
/mnt/SDCARD/System/usr/trimui/scripts/cmd_to_run_killer.sh
poweroff &
