#!/bin/sh
if [ -f "/tmp/infoscreen_disabled" ]; then
    exit
fi

# Set the library path
PATH="/mnt/SDCARD/System/bin:$PATH"
export LD_LIBRARY_PATH="/mnt/SDCARD/System/lib:/usr/trimui/lib:$LD_LIBRARY_PATH"

# Function to display usage
usage() {
    echo "Usage: [options]"
    echo "Options:"
    echo "  -i <image>      Image file to display (can be full path or just file name)"
    echo "  -k <keys>       Wait for key input (valid keys: A B Y X)"
    echo "  -t <timer>      Timer duration in seconds"
    echo "  -m <message>    Message to display"
    echo "  -ff <font_file> Font file to use"
    echo "  -fs <font_size> Font size"
    echo "  -h              Display this help message"
    echo "  -p <position>   Text position (e.g., top-left, middle-center, bottom-right)"
    echo "  -fb             Preserve framebuffer on exit"
    echo "  -fi <spacing>   Font interline/line-spacing"
    echo "  -sp             Show spinner"
    echo "  -k <map> <button> <text>  Set a button and optional label. <map>: lout|lin|rin|rout, <button>: A|B|X|Y, <text>: label to display (if empty, no label shown). Example: -key lout Y 'Left label'"
    exit 1
}

# Function to check if a value is a number (integer or floating-point)
is_number() {
    case "$1" in
    '' | *[!0-9.]* | *.*.*) return 1 ;; # Not a number
    *) return 0 ;;                      # Is a number
    esac
}

# Function to validate keys
validate_keys() {
    valid_keys="A B Y X"
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
font_file=""
position="middle-center"

Current_Theme=$(basename "$(/usr/trimui/bin/systemval theme)")
if [ "$Current_Theme" = "res" ]; then
    Current_Theme="CrossMix - OS"
fi
CrossMix_Style=$(/mnt/SDCARD/System/bin/jq -r '.["CROSSMIX STYLE"]' "/mnt/SDCARD/System/etc/crossmix.json")

# Determine font path: by default we take the one from the current theme
Current_font=$(/mnt/SDCARD/System/bin/jq -r '.["font"]' "/mnt/SDCARD/Themes/$Current_Theme/config.json")
if [ -f "/mnt/SDCARD/Themes/$Current_Theme/$Current_font" ]; then
    font_file="/mnt/SDCARD/Themes/$Current_Theme/$Current_font"
fi

# Display usage if no parameters or -h is specified
if [ $# -eq 0 ]; then
    usage
fi

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

# Initialize the base command
COMMAND="/mnt/SDCARD/System/bin/presenter"

# Parse command-line arguments
while [ "$#" -gt 0 ]; do
    case "$1" in
    -h) usage ;;
    -i)
        image="$2"
        shift 2
        ;;
    -t)
        if is_number "$2"; then
            timer="$2"
            # Add timer option if numeric
            COMMAND="$COMMAND --timeout $timer --show-time-left"
        else
            echo "Invalid timer: $2. Using default."
        fi
        shift 2
        ;;
    -ts) # silent timer
        if is_number "$2"; then
            timer="$2"
            # Add timer option if numeric
            COMMAND="$COMMAND --timeout $timer"
        else
            echo "Invalid timer: $2. Using default."
        fi
        shift 2
        ;;
    -m)
        message="${2:- }"
        # Add message option
        COMMAND="$COMMAND --message \"$message\""
        shift 2
        ;;
    -ff)
        if [ -f "$2" ]; then
            font_file="$2"
            # Add font option if file exists
            COMMAND="$COMMAND --font-default \"$font_file\""
        else
            echo "Font file $2 does not exist. Using default."
        fi
        shift 2
        ;;
    -fs)
        if [ "$2" -eq "$2" ] 2>/dev/null; then
            font_size="$2"
            # Add font-size option if defined
            COMMAND="$COMMAND --font-size-default \"$font_size\""
        else
            echo "Invalid font size: $2. Using default."
        fi
        shift 2
        ;;
    -p)
        # Text position, e.g.: "top-left", "middle-center", "bottom-right"
        position="$2"
        # Split position into vertical/horizontal
        vertical="$(echo "$position" | cut -d'-' -f1)"
        horizontal="$(echo "$position" | cut -d'-' -f2)"
        [ -n "$vertical" ] && COMMAND="$COMMAND --message-alignment $vertical"
        [ -n "$horizontal" ] && COMMAND="$COMMAND --horizontal-alignment $horizontal"
        shift 2
        ;;
    -fb)
        # Do not erase the framebuffer on exit
        COMMAND="$COMMAND --preserve-framebuffer"
        shift
        ;;
    -fi)
        # Font interline (line spacing)
        if is_number "$2"; then
            COMMAND="$COMMAND --line-spacing $2"
        else
            # Default value
            COMMAND="$COMMAND --line-spacing 0"
        fi
        shift 2
        ;;
    -sp)
        # Show spinner
        COMMAND="$COMMAND --show-spinner"
        shift
        ;;
    -k)
        # Handle -key <position> <button> <text>
        key_map="$2"
        key_button="$3"
        key_text="$4"
        validate_keys "$3"
        if [ $? -eq 0 ]; then

            case "$key_map" in
            lout) # exit code 11
                COMMAND="$COMMAND --inaction-button $key_button"
                [ -n "$key_text" ] && COMMAND="$COMMAND --inaction-text \"$key_text\" --inaction-show"
                ;;
            lin) # exit code 12
                COMMAND="$COMMAND --action-button $key_button"
                [ -n "$key_text" ] && COMMAND="$COMMAND --action-text \"$key_text\" --action-show"
                ;;
            rin) # exit code 13
                COMMAND="$COMMAND --cancel-button $key_button"
                [ -n "$key_text" ] && COMMAND="$COMMAND --cancel-text \"$key_text\" --cancel-show"
                ;;
            rout) # exit code 14
                COMMAND="$COMMAND --confirm-button $key_button"
                [ -n "$key_text" ] && COMMAND="$COMMAND --confirm-text \"$key_text\" --confirm-show"
                ;;
            esac
        fi
        shift 4
        ;;
    *) shift ;;
    esac
done

# we set default values if not set by args
image=$(determine_image_path "$image")
COMMAND="$COMMAND  --background-image \"$image\""

echo -e "infoscreen2 command line:\n$COMMAND"
eval $COMMAND
