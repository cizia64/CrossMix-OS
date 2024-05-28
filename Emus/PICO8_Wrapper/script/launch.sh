#!/bin/sh
export picodir=/mnt/SDCARD/Apps/pico
export picoconfig=$picodir/.lexaloffle/
export sysdir=/mnt/SDCARD/.tmp_update
export miyoodir=/mnt/SDCARD/miyoo
cd $picodir
export PATH=$PATH:$PWD/bin
export HOME=$picodir
export PATH=${picodir}:$PATH

get_curvol() {
    awk '/LineOut/ {if (!printed) {gsub(",", "", $8); print $8; printed=1}}' /proc/mi_modules/mi_ao/mi_ao0
}

is_process_running() {
  process_name="$1"
  if [ -z "$(pgrep -f "$process_name")" ]; then
    return 1
  else
    return 0
  fi
}

kill_audio_servers() {
    is_process_running "audioserver" && pkill -9 -f "audioserver"
    is_process_running "audioserver.mod" && killall -q "audioserver.mod"
}

runifnecessary() {
    cnt=0
    a=`ps | grep $1 | grep -v grep`
    a=$(pgrep $1)
    while [ "$a" == "" ] && [ $cnt -lt 8 ]; do
        $2 $3 &
        sleep 0.5
        cnt=$(expr $cnt + 1)
        a=$(pgrep $1)
    done
}

set_snd_level() {
    local target_vol="$1"
    local current_vol
    local start_time
    local elapsed_time

    start_time=$(date +%s)
    while [ ! -e /proc/mi_modules/mi_ao/mi_ao0 ]; do
        sleep 0.2
        elapsed_time=$(( $(date +%s) - start_time ))
        if [ "$elapsed_time" -ge 30 ]; then
            echo "Timed out waiting for /proc/mi_modules/mi_ao/mi_ao0"
            return 1
        fi
    done

    start_time=$(date +%s)
    while true; do
        echo "set_ao_volume 0 ${target_vol}dB" > /proc/mi_modules/mi_ao/mi_ao0
        echo "set_ao_volume 1 ${target_vol}dB" > /proc/mi_modules/mi_ao/mi_ao0
        current_vol=$(get_curvol)

        if [ "$current_vol" = "$target_vol" ]; then
            echo "Volume set to ${current_vol}dB"
            return 0
        fi

        elapsed_time=$(( $(date +%s) - start_time ))
        if [ "$elapsed_time" -ge 360 ]; then
            echo "Timed out trying to set volume"
            return 1
        fi

        sleep 0.2
    done
}

purge_devil() {
    if pgrep -f "/dev/l" > /dev/null; then
        echo "Process /dev/l is running. Killing it now..."
        killall -9 l
    else
        echo "Process /dev/l is not running."
    fi
}

# some users have reported black screens at boot. we'll check if the file exists, then check the keys to see if they match the known good config
fixconfig() {
    config_file="${picodir}/.lexaloffle/pico-8/config.txt"

    default_video_settings="window_size 640 480\nscreen_size 640 480\nshow_fps 0\ntransform_screen 134"
    default_window_settings="windowed 0\nwindow_position -1 -1\nframeless 1\nfullscreen_method 2\nblit_method 0"

    if [ ! -f "$config_file" ]; then
        echo "Config file not found, creating with default values."
        printf "// :: Video Settings\n%s\n\n// :: Window Settings\n%s\n" "$default_video_settings" "$default_window_settings" > "$config_file"
        return
    fi

    echo "Config checker: Validating display settings in config.txt"

    for setting in window_size screen_size windowed window_position frameless fullscreen_method blit_method transform_screen; do
        current_value=$(grep "$setting" "$config_file")

        if [ -z "$current_value" ]; then
            case $setting in
                window_size|screen_size) printf "%s 640 480\n" "$setting" >> "$config_file" ;;
                windowed) printf "%s 0\n" "$setting" >> "$config_file" ;;
                window_position) printf "%s -1 -1\n" "$setting" >> "$config_file" ;;
                frameless) printf "%s 1\n" "$setting" >> "$config_file" ;;
                fullscreen_method) printf "%s 2\n" "$setting" >> "$config_file" ;;
                blit_method) printf "%s 0\n" "$setting" >> "$config_file" ;;
                transform_screen) printf "%s 134\n" "$setting" >> "$config_file" ;;
            esac
            echo "Added missing setting: ${setting}"
        else
            echo "Current ${setting} setting: $current_value"
            case $setting in
                window_size|screen_size)
                    sed -i "s/$setting 0 0/$setting 640 480/g" "$config_file" ;;
                transform_screen)
                    sed -i "s/$setting [0-9]+/$setting 134/g" "$config_file" ;;
            esac
        fi
    done

    echo "Updated settings:"
    grep -E "window_size|screen_size|windowed|window_position|frameless|fullscreen_method|blit_method|transform_screen" "$config_file"
}

# when wifi is restarted, udhcpc and wpa_supplicant may be started with libpadsp.so preloaded, this is bad as they can hold mi_ao open even after audioserver has been killed.
libpadspblocker() { 
    wpa_pid=$(ps -e | grep "[w]pa_supplicant" | awk 'NR==1{print $1}')
    udhcpc_pid=$(ps -e | grep "[u]dhcpc" | awk 'NR==1{print $1}')
    if [ -n "$wpa_pid" ] && [ -n "$udhcpc_pid" ]; then
        if grep -q "libpadsp.so" /proc/$wpa_pid/maps || grep -q "libpadsp.so" /proc/$udhcpc_pid/maps; then
            echo "Network Checker: $wpa_pid(WPA) and $udhcpc_pid(UDHCPC) found preloaded with libpadsp.so"
            unset LD_PRELOAD
            killall -9 wpa_supplicant
            killall -9 udhcpc 
            $miyoodir/app/wpa_supplicant -B -D nl80211 -iwlan0 -c /appconfigs/wpa_supplicant.conf & 
            udhcpc -i wlan0 -s /etc/init.d/udhcpc.script &
            echo "Network Checker: Removing libpadsp.so preload on wpa_supp/udhcpc"
        fi
    fi
}

start_pico() {
    #export LD_LIBRARY_PATH="$picodir/lib:/lib:/config/lib:/mnt/SDCARD/miyoo/lib:/mnt/SDCARD/.tmp_update/lib:/mnt/SDCARD/.tmp_update/lib/parasyte:/sbin:/usr/sbin:/bin:/usr/bin"
    export LD_LIBRARY_PATH="$picodir/lib:/usr/lib:$LD_LIBRARY_PATH"
    #export SDL_VIDEODRIVER=mmiyoo
    #port SDL_AUDIODRIVER=mmiyoo
    #export EGL_VIDEODRIVER=mmiyoo
    
    #purge_devil
    #fixconfig
    #kill_audio_servers
    #libpadspblocker
    #set_snd_level "${curvol}" &
    pico8_64 -splore
}

main() {
    #echo 1008000 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq
    echo performance > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
    #curvol=$(get_curvol) # grab current volume
    mount --bind /mnt/SDCARD/Roms/PICO8 /mnt/SDCARD/Apps/pico/.lexaloffle/pico-8/carts
    start_pico
    umount /mnt/SDCARD/Apps/pico/.lexaloffle/pico-8/carts
    echo ondemand > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
}

main
