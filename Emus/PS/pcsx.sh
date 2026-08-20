#!/bin/sh
source /mnt/SDCARD/System/usr/trimui/scripts/common_launcher.sh
cpufreq.sh ondemand 3 7

cd $RA_DIR/

core_opt='/mnt/SDCARD/RetroArch/.retroarch/config/PCSX-ReARMed/PCSX-ReARMed.opt'
last_dowork="$(grep -i "dowork 0x" "/tmp/log/messages" | tail -n 1)"

if [ -f "/tmp/cmd_to_run.sh" ] && ! grep -q "dowork 0x" "/tmp/cmd_to_run.sh"; then
    sed -i "1s|^|echo \"$last_dowork\" > /tmp/log/messages\n|" "/tmp/cmd_to_run.sh"
fi

if echo "$last_dowork" | grep -q "HiRes"; then
    cpufreq.sh ondemand 6 7
    if [ -f "$core_opt.hires" ]; then
        mv "$core_opt" "$core_opt.nohires"
        mv "$core_opt.hires" "$core_opt"
    fi
else
    cpufreq.sh ondemand 3 7
    if [ -f "$core_opt.nohires" ]; then
        mv "$core_opt" "$core_opt.hires"
        mv "$core_opt.nohires" "$core_opt"
    fi
fi

HOME=$RA_DIR/ $RA_DIR/ra64.trimui -v -L $RA_DIR/.retroarch/cores/pcsx_rearmed_libretro.so "$@"
