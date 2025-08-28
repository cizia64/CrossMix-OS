#!/bin/sh
source /mnt/SDCARD/System/usr/trimui/scripts/common_launcher.sh
config_file="/mnt/SDCARD/Emus/PSP/PPSSPP/.config/ppsspp/PSP/SYSTEM/ppsspp.ini"
# cwd is EMU_DIR
cd PPSSPP

Backend=$(/mnt/SDCARD/System/bin/presenter --file /mnt/SDCARD/System/resources/PPSSPP_backend_choice.json --confirm-button A --no-wrap)
    if [ "$Backend" = "1" ]; then
	binfile="PPSSPPSDL_gl_1.17.1"
	sed -i '/^\[Graphics\]$/,/^\[/ s/GraphicsBackend = .*/GraphicsBackend = 0/' "$config_file"
	echo "--- OpenGL backend enabled"
else
	binfile="PPSSPPSDL_vulkan_1.17.1"
    sed -i '/^\[Graphics\]$/,/^\[/ s/GraphicsBackend = .*/GraphicsBackend = 3/' "$config_file"
	echo "--- Vulkan backend enabled"
    fi
	
perfmode=$(/mnt/SDCARD/System/bin/presenter --file /mnt/SDCARD/System/resources/cpu_choice.json --confirm-button A --no-wrap)
if [ "$perfmode" = "1" ]; then
    cpufreq.sh ondemand 3 6
	echo "--- on demand CPU mode enabled"
else
    cpufreq.sh performance 6 6
	echo "--- performance CPU mode enabled"
	# sed -i "1s|^|echo \"$performance\" > /tmp/log/messages\n|" "/tmp/cmd_to_run.sh"
fi


HOME=$PWD ./"$binfile" "$@"

