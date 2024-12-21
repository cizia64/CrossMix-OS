#!/bin/sh
source /mnt/SDCARD/System/usr/trimui/scripts/common_launcher.sh
cpufreq.sh ondemand 4 7

# PWD is EMU_DIR
export XDG_CONFIG_HOME="$PWD"
export XDG_DATA_HOME="$PWD"

cd mupen64plus
EMU_DIR="$PWD"

export LD_LIBRARY_PATH="$PM_DIR:$EMU_DIR:$LD_LIBRARY_PATH"

Launcher=$(grep -i "dowork 0x" "/tmp/log/messages" | tail -n 1)
if echo "$Launcher" | grep -q "Rice"; then
    set_ra_cfg.sh "$EMU_DIR/mupen64plus.cfg" "VideoPlugin" "mupen64plus-video-rice.so"
else
    [ -f "/mnt/SDCARD/trimui/app/cmd_to_run.sh" ] && fb_disable_transparency
    set_ra_cfg.sh "$EMU_DIR/mupen64plus.cfg" "VideoPlugin" "mupen64plus-video-glide64mk2.so"
    if echo "$Launcher" | grep -q "16:9"; then
        set_ra_cfg.sh "$EMU_DIR/mupen64plus.cfg" "aspect" "1"
    else
        set_ra_cfg.sh "$EMU_DIR/mupen64plus.cfg" "aspect" "0"
    fi
fi

if [ -f "/tmp/cmd_to_run.sh" ] && ! grep -q "dowork 0x" "/tmp/cmd_to_run.sh"; then
    sed -i "1s|^|echo \"$Launcher\" > /tmp/log/messages\n|" "/tmp/cmd_to_run.sh"
fi

case "$*" in
*.n64 | *.v64 | *.z64)
    ROM_PATH="$*"
    ;;
*.zip | *.7z)
    TEMP_ROM=$(mktemp)
    ROM_PATH="$TEMP_ROM"
    7zz e "$*" -so >"$TEMP_ROM"
    ;;
esac

HOTKEY=guide $PM_DIR/gptokeyb2 -c "./defkeys.gptk" &
sleep 0.3

HOME=$EMU_DIR ./mupen64plus "$ROM_PATH"

rm -f "$TEMP_ROM"

kill -9 $(pidof gptokeyb2)
