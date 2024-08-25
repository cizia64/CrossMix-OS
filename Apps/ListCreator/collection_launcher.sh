#!/bin/sh
echo $0 $*

PATH="/mnt/SDCARD/System/bin:$PATH"

RomFullPath=$1
RomPath=$(dirname "$1")
RomDir=$(basename "$RomPath")
Launcher=$(jq -r '.launch' "/mnt/SDCARD/Emus/$RomDir/config.json")
LaunchPath="/mnt/SDCARD/Emus/$RomDir/$Launcher"
		  
extension="${RomFullPath##*.}"
if [ "$extension" = "txt" ]; then
    RomFullPath=$(cat "$RomFullPath" | head -n 1) # Trick to have shortcuts: the real ROM filename is inside the text file
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
