#!/bin/sh

echo "$0 $*"

# Environment setup
export LD_LIBRARY_PATH=./lib:/mnt/SDCARD/System/lib:$LD_LIBRARY_PATH
export PATH="/mnt/SDCARD/System/bin:/mnt/SDCARD/System/usr/trimui/scripts:$PATH"

progdir="$(dirname "$0")"
cd /mnt/SDCARD/Emus/JAVA/zulu17/bin || exit 1

JAVA_HOME='/mnt/SDCARD/Emus/JAVA/zulu17'
export JAVA_HOME
PATH="$JAVA_HOME/bin:$PATH"
export PATH
CLASSPATH="$JAVA_HOME/lib:$CLASSPATH"
export CLASSPATH
LD_LIBRARY_PATH="$JAVA_HOME/lib:$LD_LIBRARY_PATH"
export LD_LIBRARY_PATH
TIMIDITY_CFG="/mnt/SDCARD/Emus/JAVA/timidity/timidity.cfg"
export TIMIDITY_CFG
JAVA_TOOL_OPTIONS='-Xverify:none -Djava.util.prefs.systemRoot=./.java -Djava.util.prefs.userRoot=./.java/.userPrefs -Djava.awt.headless=true -Dsun.jnu.encoding=UTF-8 -Dfile.encoding=UTF-8 -Djava.library.path=/mnt/SDCARD/Emus/JAVA/zulu17/lib'
export JAVA_TOOL_OPTIONS

# Java prefs directories
mkdir -p ./.java/.systemPrefs
mkdir -p ./.java/.userPrefs

rom_path="$*"
rom_name="$(basename "$rom_path" .jar)"
config_dir="/mnt/SDCARD/Emus/JAVA/zulu17/bin/config"
resolutions="240x320 320x240 128x128 176x208 640x360"

infoscreen.sh -i "$Current_bg" -m "running ${rom_name}" &

# Read last launcher command from logs
Launcher=$(grep -i "dowork 0x" "/tmp/log/messages" | tail -n 1)

# Helper: delete other config folders and rename rms folder
update_configs() {
    # Delete other config folders
    for dir in "$config_dir/${rom_name}"*; do
        if [ -d "$dir" ] && [ "$dir" != "$config_dir/${rom_name}${resx}${resy}" ]; then
            rm -rf "$dir"
        fi
    done

    # Rename RMS folder if needed
    rms_dir_base="/mnt/SDCARD/Emus/JAVA/zulu17/bin/rms"
    current_rms="$(find "$rms_dir_base" -type d -name "${rom_name}*" | grep -v "${rom_name}${resx}${resy}" | head -n1)"

    if [ -n "$current_rms" ]; then
        new_rms="${rms_dir_base}/${rom_name}${resx}${resy}"
        echo "Renaming RMS folder: $(basename "$current_rms") -> $(basename "$new_rms")"
        mv "$current_rms" "$new_rms"
    fi
}


# Helper: launch selector and set resx/resy
choose_resolution() {
    selector_output=$(selector -t "Choose resolution for $rom_name:" -c $resolutions)
    selected="${selector_output#*: }"
    case "$selected" in
        "240x320") resx=240; resy=320 ;;
        "320x240") resx=320; resy=240 ;;
        "128x128") resx=128; resy=128 ;;
        "176x208") resx=176; resy=208 ;;
        "640x360") resx=640; resy=360 ;;
        *) echo "Cancelled."; exit 0 ;;
    esac
}

# 1. Force selector if "Switch resolution" is detected in logs
if echo "$Launcher" | grep -q "Switch resolution"; then
    echo "Resolution switch requested via logs"
    choose_resolution
    update_configs

# 2. Check for forced resolution in logs
elif echo "$Launcher" | grep -Eq "240x320|320x240|128x128|176x208|640x360"; then
    echo "Resolution detected in logs"
    case "$Launcher" in
        *240x320*) resx=240; resy=320 ;;
        *320x240*) resx=320; resy=240 ;;
        *128x128*) resx=128; resy=128 ;;
        *176x208*) resx=176; resy=208 ;;
        *640x360*) resx=640; resy=360 ;;
    esac
    update_configs

# 3. Try existing config folder
else
    for res in $resolutions; do
        resx="${res%x*}"
        resy="${res#*x}"
        if [ -d "$config_dir/${rom_name}${resx}${resy}" ]; then
            echo "Existing config found: ${resx}x${resy}"
			thd --triggers /mnt/SDCARD/Emus/JAVA/thd.conf /dev/input/event3 &
            exec java -jar freej2me-sdl.jar "$rom_path" "$resx" "$resy" 100
			pkill -f "thd --triggers /mnt/SDCARD/Emus/JAVA/thd.conf /dev/input/event3"
        fi
    done

    # 4. Fallback to selector if no config found
    echo "No config found, launching selector"
    choose_resolution
fi

# Final launch
thd --triggers /mnt/SDCARD/Emus/JAVA/thd.conf /dev/input/event3 &
java -jar freej2me-sdl.jar "$rom_path" "$resx" "$resy" 100
pkill -f "thd --triggers /mnt/SDCARD/Emus/JAVA/thd.conf /dev/input/event3"