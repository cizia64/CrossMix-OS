export PATH="/mnt/SDCARD/System/usr/trimui/scripts/:/mnt/SDCARD/System/bin:${PATH:+:$PATH}"
export LD_LIBRARY_PATH="/usr/trimui/lib:/mnt/SDCARD/System/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
RA_DIR="/mnt/SDCARD/RetroArch"
EMU_DIR="$(dirname "$0")"

dir=/mnt/SDCARD/System/usr/trimui/scripts/launchers

if grep -q ra64.trimui "$0"; then
    source $dir/FolderOverrideFinder.sh

    ra_audio_switcher.sh
fi

source $dir/save_launcher.sh
cd $EMU_DIR
