#!/bin/sh
source /mnt/SDCARD/System/usr/trimui/scripts/common_launcher.sh
config_file="/mnt/SDCARD/Emus/PSP/PPSSPP/.config/ppsspp/PSP/SYSTEM/ppsspp.ini"

# cwd is EMU_DIR
cd PPSSPP


performance=$(grep -i "dowork 0x" "/tmp/log/messages" | tail -n 1 | grep -i "Perf.") # We detect the performance mode from the label which have been selected in launcher menu
if [ -n "$performance" ]; then
    cpufreq.sh performance 6 6
    launcher_settings="Perf."
else
    cpufreq.sh ondemand 3 6
fi


backend=$(grep -i "dowork 0x" "/tmp/log/messages" | tail -n 1 | grep -i "Vulkan") # We detect the selected backend from the label in launcher menu
if [ -n "$backend" ]; then
    # We set the Backend to Vulkan
    launcher_settings="$launcher_settings Vulkan dowork 0x"
    sed -i '/^\[Graphics\]$/,/^\[/ s/GraphicsBackend = .*/GraphicsBackend = 3/' "$config_file"
    
else
    # We set the Backend to OpenGL
    sed -i '/^\[Graphics\]$/,/^\[/ s/GraphicsBackend = .*/GraphicsBackend = 0/' "$config_file"
fi

# to restore PPSSPP launcher settings when resume at boot:
echo "--- launcher settings: $launcher_settings"
sed -i "1s|^|echo \"$launcher_settings\" > /tmp/log/messages\n|" "/tmp/cmd_to_run.sh"


#export SDL_AUDIODRIVER=dsp   //disable 20231031 for sound suspend issue
export LD_LIBRARY_PATH="/usr/trimui/lib"
HOME=$PWD ./PPSSPPSDL_1.19.0 "$*"
