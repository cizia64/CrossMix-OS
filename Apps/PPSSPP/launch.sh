#!/bin/sh

export PATH="/mnt/SDCARD/System/usr/trimui/scripts:/mnt/SDCARD/System/bin${PATH:+:$PATH}"
export LD_LIBRARY_PATH="/usr/trimui/lib:/mnt/SDCARD/System/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

cd /mnt/SDCARD/Emus/PSP/PPSSPP_1.17.1 || exit 1

cpufreq.sh ondemand 3 6

# Use the same OpenGL backend and configuration as the PSP launcher.
sed -i '/^\[Graphics\]$/,/^\[/ s/GraphicsBackend = .*/GraphicsBackend = 0/' .config/ppsspp/PSP/SYSTEM/ppsspp.ini

HOME="$PWD" exec ./PPSSPPSDL_gl
