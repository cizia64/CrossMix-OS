#!/bin/sh
source /mnt/SDCARD/System/usr/trimui/scripts/common_launcher.sh
cpufreq.sh ondemand 5 7

cd $RA_DIR/

if ! find "/mnt/SDCARD/BIOS" -maxdepth 1 -iname "scph*" -o -iname "psxonpsp660.bin" -o -iname "ps*.bin" | grep -q .; then
	/mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -i bg-exit.png -m "No bios found, SwanStation will probably not work." -k " "
fi

last_dowork="$(grep -i "dowork 0x" "/tmp/log/messages" | tail -n 1)"

if [ -f "/tmp/cmd_to_run.sh" ] && ! grep -q "dowork 0x" "/tmp/cmd_to_run.sh"; then
    sed -i "1s|^|echo \"$last_dowork\" > /tmp/log/messages\n|" "/tmp/cmd_to_run.sh"
fi

core_opt='/mnt/SDCARD/RetroArch/.retroarch/config/SwanStation/SwanStation.opt'
sys_cfg='/mnt/SDCARD/RetroArch/.retroarch/config/SwanStation/PS.cfg'

if echo "$last_dowork" | grep -q "16:9"; then
    if [ -f "$core_opt.wide" ]; then
        mv "$core_opt" "$core_opt.nowide"
        mv "$core_opt.wide" "$core_opt"
    fi
    if [ -f "$sys_cfg.wide" ]; then
        mv "$sys_cfg" "$sys_cfg.nowide"
        mv "$sys_cfg.wide" "$sys_cfg"
    fi
else
    if [ -f "$core_opt.nowide" ]; then
        mv "$core_opt" "$core_opt.wide"
        mv "$core_opt.nowide" "$core_opt"
    fi
    if [ -f "$sys_cfg.nowide" ]; then
        mv "$sys_cfg" "$sys_cfg.wide"
        mv "$sys_cfg.nowide" "$sys_cfg"
    fi
fi

HOME=$RA_DIR/ $RA_DIR/ra64.trimui -v -L $RA_DIR/.retroarch/cores/swanstation_libretro.so "$@"
