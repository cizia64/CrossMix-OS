#!/bin/sh
export LD_LIBRARY_PATH=/mnt/SDCARD/System/lib/:/lib:/lib64:/mnt/SDCARD/Apps/PortMaster/PortMaster:/usr/lib:LD_LIBRARY_PATH

settings_file="/mnt/SDCARD/Apps/MusicPlayer/gmu.settings.conf"
first_run_file="/mnt/SDCARD/Apps/MusicPlayer/FirstRunDone"

cd /mnt/SDCARD/Apps/MusicPlayer

/mnt/SDCARD/Apps/PortMaster/PortMaster/gptokeyb2 "gmu.bin" -c "/mnt/SDCARD/Apps/MusicPlayer/trimui_smart_pro.gptk" &
sleep 0.4

# To support LCD switch-Off key combination
/mnt/SDCARD/System/bin/thd --triggers /mnt/SDCARD/Apps/MusicPlayer/ahk.conf /dev/input/event3 &

echo 1 >/tmp/stay_awake
HOME=/mnt/SDCARD/Apps/MusicPlayer /mnt/SDCARD/Apps/MusicPlayer/gmu.bin -c gmu.settings.conf
rm /tmp/stay_awake

kill -9 $(pidof gptokeyb2)
kill -9 $(pidof thd)

# Check if the FirstRunDone file exists
if ! [ -f "$first_run_file" ]; then
    sed -i 's/^Gmu.FirstRun=.*/Gmu.FirstRun=no/' "$settings_file"
    touch "$first_run_file"
fi

sync
