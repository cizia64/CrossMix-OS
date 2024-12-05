#!/bin/sh
echo $0 $*

PATH="/mnt/SDCARD/System/bin:$PATH"

RomFullPath=$1
RomPath=$(dirname "$1")
RomDir=$(basename "$RomPath")
Config="/mnt/SDCARD/Emus/$RomDir/config.json"
Launcher=$(jq -r '.launch' "$Config")
LaunchPath="/mnt/SDCARD/Emus/$RomDir/$Launcher"

extension="${RomFullPath##*.}"
if [ "$extension" = "txt" ]; then
    RomFullPath=$(cat "$RomFullPath" | head -n 1) # Trick to have shortcuts: the real ROM filename is inside the text file
fi

if [ "$extension" = "launch" ]; then
    source "$RomFullPath"
fi

echo "***************************************************************************"
echo "RomFullPath  $RomFullPath"
echo "RomPath      $RomPath"
echo "RomDir       $RomDir"
echo "LaunchPath   $LaunchPath"
echo "***************************************************************************"

#  Example:
#  ***************************************************************************
#  RomFullPath   /mnt/SDCARD/Best/Free Games Collection/./Roms/ATARI2600/Sheep It Up.zip
#  RomPath       /mnt/SDCARD/Best/Free Games Collection/./Roms/ATARI2600
#  RomDir        ATARI2600
#  LaunchPath    /mnt/SDCARD/Emus/ATARI2600/launch.sh
#  ***************************************************************************

if [ -f "$LaunchPath" ]; then

    # Launcher selector
    /mnt/SDCARD/System/usr/trimui/scripts/button_state.sh X
    if [ $? -eq 10 ] && jq -e ".launchlist" "$Config"; then
        selected=$(jq -c '.launchlist[] | .name' "$Config" | xargs selector -t "$RomDir launchers: " -c)
        if echo "$selected" | grep -q "You selected: "; then
            Launcher_name="${selected#*: }"
            Launcher=$(jq -r --arg name "$Launcher_name" \
                '.launchlist[] | select(.name == $name) | .launch' "$Config")
            if [ -n "$Launcher" ]; then
                echo "collection launcher: $Launcher_name dowork 0x" >>/tmp/log/messages
                LaunchPath=/mnt/SDCARD/Emus/$RomDir/$Launcher
            fi
        fi
    fi

    "$LaunchPath" "$RomFullPath"

else

    #########################################################################################
    # this section is only useful if standard Roms directory are not used #
    # Select core based on name of containing folder
    case $(echo "$(basename "$RomPath")" | awk '{print toupper($0)}') in
    ARCADE)
        core="mame2003_plus_libretro.so"
        ;;
        # PS)
        # core="duckstation_libretro.so"
        # ;;
    *) ;;
    esac

    cd /mnt/SDCARD/RetroArch/
    HOME=/mnt/SDCARD/RetroArch/ ./ra64.trimui -v -L ".retroarch/cores/$core" "$RomFullPath"
    #########################################################################################

fi
