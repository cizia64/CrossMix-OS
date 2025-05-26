#!/bin/sh

# Exit if OSD is not currently visible
if [ ! -f "/tmp/trimui_osd/osdd_show_up" ]; then
    exit
fi

# we use a background function to avoid to free the OSB during update execution
refresh_osd_info_widget() {
    # Create a lock file to avoid concurrent executions
    LOCKFILE="/tmp/update_app_info.lock"
    exec 200>"$LOCKFILE"

    # Try to acquire an exclusive non-blocking lock
    flock -n 200 || {
        echo "OSD info refresh is already in progress. Exiting."
        return 0
    }

    /usr/trimui/osd/widgets/app_info/get_info.sh
    /mnt/SDCARD/System/bin/python3.11 ./text_image.py || rm "/tmp/crossmix_info/app_info.png"
    # /mnt/SDCARD/System/bin/python3.11 /usr/trimui/osd/widgets/app_info/check_image.py
    
    
    
if [ -f "/tmp/crossmix_info/app_info.png" ]; then
    TMP_FILE="/tmp/crossmix_info/.vfb_osd_tmp"
    FINAL_FILE="/tmp/crossmix_info/vfb_osd"

    ./pic2argb /tmp/crossmix_info/app_info.png "$TMP_FILE" || {
        echo "Image conversion failed. Cleaning up."
        rm -f "$TMP_FILE"
        exit 1
    }

    killall -SIGSTOP trimui_osdd 2>/dev/null
    cat "$TMP_FILE" > "$FINAL_FILE" && rm -f "$TMP_FILE"
    killall -SIGCONT trimui_osdd 2>/dev/null
fi

}

CUR_DIR=$(dirname "$0")
cd "$CUR_DIR"

# Run the update function in the background
refresh_osd_info_widget &
