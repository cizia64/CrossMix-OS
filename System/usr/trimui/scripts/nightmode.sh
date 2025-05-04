#!/bin/sh

NIGHTMODE_FLAG="/tmp/nightmode"
BACKUP_FILE="/tmp/display_settings_backup.conf"
CONFIG_FILE="/mnt/SDCARD/System/etc/nightmode.conf"

PARAMS="
backlight
color_temperature
enhance_bright
enhance_contrast
enhance_saturation
"

# Initialize the config if it doesn't exist
init_config() {
    [ -f "$CONFIG_FILE" ] && return
    cat > "$CONFIG_FILE" <<EOF
backlight=22
color_temperature=235
enhance_bright=50
enhance_contrast=20
enhance_saturation=50
EOF
}

get_param() {
    cat "/sys/class/disp/disp/attr/$1" 2>/dev/null
}

set_param() {
    echo "$2" > "/sys/class/disp/disp/attr/$1" 2>/dev/null
}

get_config_value() {
    grep "^$1=" "$CONFIG_FILE" | cut -d= -f2
}

set_backlight() {
    echo lcd0 > /sys/kernel/debug/dispdbg/name
    echo setbl > /sys/kernel/debug/dispdbg/command
    echo "$1" > /sys/kernel/debug/dispdbg/param
    echo 1 > /sys/kernel/debug/dispdbg/start
}

backup_current_settings() {
    echo "📦 Saving current display settings"
    > "$BACKUP_FILE"
    for p in $PARAMS; do
        if [ "$p" = "backlight" ]; then
            sttbrt=$(/usr/trimui/bin/shmvar brightness 2>/dev/null)
            if [ -n "$sttbrt" ]; then
                val=$(printf "%.0f" "$(echo "$sttbrt * 23" | bc)")
            else
                val=200
            fi
        else
            val=$(get_param "$p")
        fi
        echo "$p=$val" >> "$BACKUP_FILE"
    done
}

restore_settings() {
    echo "♻️ Restoring previous display settings"
    [ -f "$BACKUP_FILE" ] || { echo "⚠️ No backup file found."; return; }

    while IFS='=' read -r key val; do
        if [ "$key" = "backlight" ]; then
            set_backlight "$val"
            echo "  backlight: $val"
        else
            set_param "$key" "$val"
            echo "  $key: $val"
        fi
    done < "$BACKUP_FILE"
}

set_night_mode() {
    backup_current_settings
    echo "🌙 Enabling night mode"

    for p in $PARAMS; do
        val=$(get_config_value "$p")
        if [ "$p" = "backlight" ]; then
            set_backlight "$val"
            echo "  backlight: $val"
        else
            set_param "$p" "$val"
            echo "  $p: $val"
        fi
    done

    touch "$NIGHTMODE_FLAG"
    if ! pgrep -f com.crossmix.nightmode.sh >/dev/null; then
        /usr/trimui/osd/show_info_msg.sh "night mode enabled"
    fi
}

set_day_mode() {
    echo "🌞 Disabling night mode"
    restore_settings
    rm "$NIGHTMODE_FLAG"
    if ! pgrep -f com.crossmix.nightmode.sh >/dev/null; then
        /usr/trimui/osd/show_info_msg.sh "night mode disabled"
    fi
}

print_current_settings() {
    echo "Current display settings:"
    for p in $PARAMS; do
        if [ "$p" = "backlight" ]; then
            value=$(cat /sys/kernel/debug/dispdbg/param)
            if [ -z "$value" ] || [ "$value" = "0" ]; then
                sttbrt=$(/usr/trimui/bin/shmvar brightness 2>/dev/null)
                if [ -n "$sttbrt" ]; then
                    value=$(printf "%.0f" "$(echo "$sttbrt * 23" | bc)")
                else
                    value=200
                fi
            fi
        else
            value=$(get_param "$p")
        fi
        echo "$p = $value"
    done
}

update_config() {
    param="$1"
    value="$2"
    if echo "$PARAMS" | grep -qw "$param"; then
        echo "Updating $param to $value"
        sed -i "s/^$param=.*/$param=$value/" "$CONFIG_FILE"
        # Apply immediately
        if [ "$param" = "backlight" ]; then
            set_backlight "$value"
        else
            set_param "$param" "$value"
        fi
    else
        echo "Unknown parameter: $param"
    fi
}

# Initialization
init_config
sync

# Command-line arguments
case "$1" in
    -night)
        if [ ! -f "$NIGHTMODE_FLAG" ]; then
            set_night_mode
        fi
        ;;
    -day)
        set_day_mode
        ;;
    -i)
        print_current_settings
        ;;
    -set)
        [ -n "$2" ] && [ -n "$3" ] && update_config "$2" "$3"
        sync
        ;;
    *)
        if [ ! -f "$NIGHTMODE_FLAG" ]; then
            set_night_mode
        else
            set_day_mode
        fi
        ;;
esac
