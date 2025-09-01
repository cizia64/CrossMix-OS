#!/bin/sh
source /mnt/SDCARD/System/usr/trimui/scripts/common_launcher.sh
config_file="/mnt/SDCARD/Emus/PSP/PPSSPP/.config/ppsspp/PSP/SYSTEM/ppsspp.ini"
# cwd is EMU_DIR
cd PPSSPP_1.15.4

	
perfmode=$(/mnt/SDCARD/System/bin/presenter --file /mnt/SDCARD/System/resources/cpu_choice.json --confirm-button A --no-wrap)
if [ "$perfmode" = "1" ]; then
    cpufreq.sh ondemand 3 6
	echo "--- on demand CPU mode enabled"
else
    cpufreq.sh performance 6 6
	echo "--- performance CPU mode enabled"
	# sed -i "1s|^|echo \"$performance\" > /tmp/log/messages\n|" "/tmp/cmd_to_run.sh"
fi

export LD_LIBRARY_PATH="/usr/trimui/lib" # "/mnt/SDCARD/System/lib" = segfault
HOME=$PWD ./PPSSPPSDL "$@"

