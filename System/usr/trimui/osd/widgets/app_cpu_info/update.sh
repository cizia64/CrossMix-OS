#!/bin/sh

# Exit if cpu OSD is not currently visible
if [ ! -f "/tmp/trimui_osd/osdd_show_u3" ]; then
    exit
fi

# we use a background function to avoid to free the OSB during update execution
refresh_osd_cpu_info_widget() {

    # Create a lock file to avoid concurrent executions
    LOCKFILE="/tmp/update_app_cpu_info.lock"
    exec 200>"$LOCKFILE"

    # Try to acquire an exclusive non-blocking lock
    flock -n 200 || {
        echo "OSD info refresh is already in progress. Exiting."
        return 0
    }

    # refresh sliders
    ../slider_cpu_active/set.sh &
    ../slider_cpu_governor/set.sh &
    ../slider_cpu_max_freq/set.sh &
    ../slider_cpu_min_freq/set.sh &
    ../slider_cpu_preset/set.sh &

    ./get_info.sh
    /mnt/SDCARD/System/bin/python3.11 ./text_image.py || rm "/tmp/crossmix_cpu_info/app_cpu_info.png"
    # /mnt/SDCARD/System/bin/python3.11 /usr/trimui/osd/widgets/app_info/check_image.py

    if [ -f "/tmp/crossmix_cpu_info/app_cpu_info.png" ]; then
        TMP_FILE="/tmp/crossmix_cpu_info/.vfb_osd_tmp"
        FINAL_FILE="/tmp/crossmix_cpu_info/vfb_osd"

        ./pic2argb /tmp/crossmix_cpu_info/app_cpu_info.png "$TMP_FILE" || {
            echo "Image conversion failed. Cleaning up."
            rm -f "$TMP_FILE"
            exit 1
        }

        killall -SIGSTOP cpuinfo_osdd
        cat "$TMP_FILE" >"$FINAL_FILE" && rm -f "$TMP_FILE"
        killall -SIGCONT cpuinfo_osdd

    fi

}

CUR_DIR=$(dirname "$0")
cd "$CUR_DIR"

# Run the update function in the background
refresh_osd_cpu_info_widget &
