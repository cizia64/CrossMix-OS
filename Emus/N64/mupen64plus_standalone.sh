#!/bin/sh
source /mnt/SDCARD/System/usr/trimui/scripts/common_launcher.sh
cpufreq.sh ondemand 4 7

EMU_DIR=/mnt/SDCARD/Emus/N64/mupen64plus
CONFDIR="/mnt/SDCARD/Emus/N64"
export XDG_CONFIG_HOME="$CONFDIR"
export XDG_DATA_HOME="$CONFDIR"
export FRT_NO_EXIT_SHORTCUTS=FRT_NO_EXIT_SHORTCUTS

PATH=$EMU_DIR:$PATH
export LD_LIBRARY_PATH=$EMU_DIR:$EMU_DIR/libs:$LD_LIBRARY_PATH

cd "$EMU_DIR"
VideoPlugin=$(grep -i "dowork 0x" "/tmp/log/messages" | tail -n 1 | grep -i "Rice") # We detect the performance mode from the label which have been selected in launcher menu
if [ -n "$VideoPlugin" ]; then
    /mnt/SDCARD/System/usr/trimui/scripts/set_ra_cfg.sh "$EMU_DIR/mupen64plus.cfg" "VideoPlugin" "mupen64plus-video-rice.so"
else
    VideoPlugin=$(grep -i "dowork 0x" "/tmp/log/messages" | tail -n 1 | grep -i "glide64mk2 - 16:9") # We detect the performance mode from the label which have been selected in launcher menu
    if [ -n "$VideoPlugin" ]; then
        /mnt/SDCARD/System/usr/trimui/scripts/set_ra_cfg.sh "$EMU_DIR/mupen64plus.cfg" "aspect" "1"
    else
        /mnt/SDCARD/System/usr/trimui/scripts/set_ra_cfg.sh "$EMU_DIR/mupen64plus.cfg" "aspect" "0"
    fi
    /mnt/SDCARD/System/usr/trimui/scripts/set_ra_cfg.sh "$EMU_DIR/mupen64plus.cfg" "VideoPlugin" "mupen64plus-video-glide64mk2.so"
fi

case "$*" in
*.n64 | *.v64 | *.z64)
    ROM_PATH="$*"
    ;;
*.zip | *.7z)
    TEMP_ROM=$(mktemp)
    ROM_PATH="$TEMP_ROM"
    /mnt/SDCARD/System/bin/7zz e "$*" -so >"$TEMP_ROM"
    ;;
esac


/mnt/SDCARD/Apps/PortMaster/PortMaster/gptokeyb2 -c "./defkeys.gptk" &
sleep 0.3

HOME="$EMU_DIR" ./mupen64plus "$ROM_PATH"

rm -f "$TEMP_ROM"

kill -9 $(pidof gptokeyb2)
