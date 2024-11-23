#!/bin/sh
settings_file="/mnt/SDCARD/Apps/MusicPlayer/gmu.settings.conf"
sed -i 's/^Gmu.AutoPlayOnProgramStart=yes$/Gmu.AutoPlayOnProgramStart=no/' "$settings_file"
sync

./gmu_launcher.sh
