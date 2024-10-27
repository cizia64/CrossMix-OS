#!/bin/sh
# echo performance >/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor

# Function to display usage
usage() {
    echo "Usage: [options]"
    echo "Options:"
    echo "  -i <image>      Image file to display (can be full path or just file name)"
    echo "  -k <keys>       Wait for key input (valid keys: A B Y X L R SELECT START MENU FN UP DOWN LEFT RIGHT FN_RIGHT FN_LEFT)"
    echo "  -t <timer>      Timer duration in seconds"
    echo "  -m <message>    Message to display"
    echo "  -ff <font_file> Font file to use"
    echo "  -fs <font_size> Font size"
    echo "  -c <color>      Color (name or RGB format, e.g., red or 255,0,0)"
    echo "  -h              Display this help message"
    exit 1
}

# Function to convert color names to RGB values
color_to_rgb() {
    case "$1" in
    red) echo "255,0,0" ;;
    green) echo "0,255,0" ;;
    blue) echo "0,0,255" ;;
    white) echo "255,255,255" ;;
    black) echo "0,0,0" ;;
    yellow) echo "255,255,0" ;;
    cyan) echo "0,255,255" ;;
    magenta) echo "255,0,255" ;;
    gray | grey) echo "128,128,128" ;;
    lightgray | lightgrey) echo "192,192,192" ;;
    darkgray | darkgrey) echo "64,64,64" ;;
    brown) echo "165,42,42" ;;
    orange) echo "255,165,0" ;;
    purple) echo "128,0,128" ;;
    pink) echo "255,119,170" ;;
    *) echo "$1" ;; # If it's not a named color, assume it's already in RGB format
    esac
}


# Function to check if a value is a number (integer or floating-point)
is_number() {
    case "$1" in
        ''|*[!0-9.]*|*.*.*) return 1 ;;  # Not a number
        *) return 0 ;;                    # Is a number
    esac
}

# Function to validate keys
validate_keys() {
    valid_keys="A B Y X L R SELECT START MENU FN UP DOWN LEFT RIGHT FN_RIGHT FN_LEFT"
    for key in $1; do
        if ! echo "$valid_keys" | grep -qw "$key"; then
            echo "Invalid key: $key. Using default."
            return 1
        fi
    done
    return 0
}

# Initialize variables with default values
image="bg-info.png"
wait_keys=""
timer=""
message=" "
font_file="/mnt/SDCARD/System/resources/DejaVuSans.ttf"
font_size=35
color="220,220,220"

Current_Theme=$(basename "$(/usr/trimui/bin/systemval theme)")
CrossMix_Style=$(/mnt/SDCARD/System/bin/jq -r '.["CROSSMIX STYLE"]' "/mnt/SDCARD/System/etc/crossmix.json")

# Determine font path : by default we take the one from the current theme
Current_font=$(/mnt/SDCARD/System/bin/jq -r '.["font"]' "/mnt/SDCARD/Themes/$Current_Theme/config.json")
if [ -f "/mnt/SDCARD/Themes/$Current_Theme/$Current_font" ]; then
    font_file="/mnt/SDCARD/Themes/$Current_Theme/$Current_font"
fi

# Display usage if no parameters or -h is specified
if [ $# -eq 0 ]; then
    usage
fi

# Parse command-line arguments
while [ "$#" -gt 0 ]; do
    case "$1" in
        -h) usage ;;
        -i) image="$2"; shift 2 ;;
        -k)
            validate_keys "$2"
            if [ $? -eq 0 ]; then
                wait_keys="$2"
            fi
            shift 2 ;;
        -t)
            if is_number "$2"; then
                timer="$2"
            else
                echo "Invalid timer: $2. Using default."
            fi
            shift 2 ;;
        -m) message="${2:- }"; shift 2 ;;
        -ff)
            if [ -f "$2" ]; then
                font_file="$2"
            else
                echo "Font file $2 does not exist. Using default."
            fi
            shift 2 ;;
        -fs)
            if [ "$2" -eq "$2" ] 2>/dev/null; then
                font_size="$2"
            else
                echo "Invalid font size: $2. Using default."
            fi
            shift 2 ;;
        -c) color=$(color_to_rgb "$2"); shift 2 ;;
        *) shift ;;
    esac
done

# Function to determine the image path
determine_image_path() {
    image_name="$1"
    base_path="/mnt/SDCARD/trimui/res/crossmix-os"

    # Check if image is a full path
    if [ -f "$image_name" ]; then
        base_path=$(dirname "$image_name")

        # Check if themed image exists
        themed_image="$base_path/style_$CrossMix_Style/$(basename "$image_name")"
        if [ -f "$themed_image" ]; then
            echo "$themed_image"
            return
        fi

        echo "$image_name"
        return
    fi

    # Check if themed image exists
    themed_image="$base_path/style_$CrossMix_Style/$image_name"
    if [ -f "$themed_image" ]; then
        echo "$themed_image"
        return
    fi

    # Check if image is in the base path
    if [ -f "$base_path/$image_name" ]; then
        echo "$base_path/$image_name"
        return
    fi

    # Default image
    echo "$base_path/bg-info.png"
}

# Determine the actual image path
image=$(determine_image_path "$image")

# Set the library path
PATH="/mnt/SDCARD/System/bin:$PATH"
export LD_LIBRARY_PATH="/mnt/SDCARD/System/lib:/usr/trimui/lib:$LD_LIBRARY_PATH"

touch /var/trimui_inputd/sticks_disabled

# Run the sdl2imgshow command
/mnt/SDCARD/System/bin/sdl2imgshow \
    -i "$image" \
    -f "$font_file" \
    -s "$font_size" \
    -c "$color" \
    -t "$message" \
    >/dev/null 2>&1 &

# Function to handle the timer
handle_timer() {
    if [ -n "$timer" ]; then
	sleep 1
        sleep "$timer"
        for pid in $(pgrep -f getkey.sh); do pkill -TERM -P $pid; done
    fi
}

# Start the timer and key wait handlers concurrently


if [ -n "$wait_keys" ]; then
    handle_timer &
    handle_timer_pid=$!
    button=$(/mnt/SDCARD/System/usr/trimui/scripts/getkey.sh "$wait_keys" 2>/dev/null)
    if [ -z "$button" ]; then
        button="timeout" # the timer has completed the script before the user presses a key
    fi
    echo "$button"
    kill -9 $handle_timer_pid 2>/dev/null
else
        handle_timer
fi

pkill -f sdl2imgshow

rm /var/trimui_inputd/sticks_disabled
# echo ondemand >/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
