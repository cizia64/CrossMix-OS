#!/bin/sh

# Expect a ROM file path as the first argument
ROM_PATH="$1"
if [ -z "$ROM_PATH" ]; then
    echo "Usage: source $0 /path/to/romfile"
    return 1
fi

EMU_DIR_BASENAME="$(basename "$EMU_DIR")"

# Environment variables expected
: "${Launcher_name:=None}"
: "${Preset_Type:=None}"

# Path to the romscripts folder
SCRIPT_DIR="/mnt/SDCARD/System/usr/trimui/scripts/romscripts"

choices=""
declare_mapping=""

# Add a choice to selector
# $1 = real relative path (ex: "myscript.sh" or "folder/myscript.sh")
# $2 = filename only (ex: "myscript.sh")
add_choice() {
    local real_path="$1"
    local filename="$2"
    local display_name="${filename%.sh}"

    # Replace variables in display name
    display_name="${display_name//EMU_DIR/$EMU_DIR_BASENAME}"
    display_name="${display_name//PRESET_TYPE/$Preset_Type}"

    # If no preset is selected, do not add the specific "Remove current PRESET_TYPE preset.sh" choice
    if [ "$Preset_Type" = "None" ]; then
        case "$real_path" in
            */Remove\ current\ PRESET_TYPE\ preset.sh|Remove\ current\ PRESET_TYPE\ preset.sh)
                return 0 ;;
        esac
    fi

    # Store for selector and mapping
    choices="$choices \"$display_name\""
    declare_mapping="$declare_mapping$display_name|$real_path"$'\n'
}

# Scan root-level scripts
if [ -d "$SCRIPT_DIR" ]; then
    for filepath in "$SCRIPT_DIR"/*.sh; do
        [ -e "$filepath" ] || continue
        filename=$(basename "$filepath")
        case "$filename" in .* ) continue ;; esac
        add_choice "$filename" "$filename"
    done

    # Scan subfolders
    for subdir in "$SCRIPT_DIR"/*/; do
        [ -d "$subdir" ] || continue
        subdirname=$(basename "$subdir")
        case "$subdirname" in .* ) continue ;; esac

        # Replace variables in folder name
        display_header="$subdirname"
        display_header="${display_header// LAUNCHER_NAME/: $Launcher_name}"
        display_header="${display_header// PRESET_TYPE/: $Preset_Type}"

        header="------- $display_header -------"
        choices="$choices \"$header\""

        # Scripts inside this folder
        for filepath in "$subdir"/*.sh; do
            [ -e "$filepath" ] || continue
            filename=$(basename "$filepath")
            case "$filename" in .* ) continue ;; esac
            add_choice "$subdirname/$filename" "$filename"
        done
    done
fi

# Abort if no scripts found
if [ -z "$choices" ]; then
    echo "No scripts found in $SCRIPT_DIR"
    return 1
fi

# Show selector menu
eval "selector_output=\$(selector -i /mnt/SDCARD/trimui/res/crossmix-os/bg-plain.png -t \"Choose an action for $ROM_FILENAME_NOEXT\" -fs 150 -c $choices)"
selected_name=$(printf '%s\n' "$selector_output" | sed 's/^.*: //')

# Exit if no selection
if [ -z "$selected_name" ]; then
    echo "No selection made."
    return 0
fi

# If a header was selected, ignore
case "$selected_name" in
    "------- "*)
        case "$selected_name" in *" -------") 
            echo "No action for group header."
            return 0 ;;
        esac
        ;;
esac

# Map displayed name back to real filename
real_filename=$(printf '%s\n' "$declare_mapping" | awk -F'|' -v sel="$selected_name" '$1 == sel {print $2; exit}')

if [ -z "$real_filename" ]; then
    echo "Error: Could not map selection to real filename."
    return 1
fi

# Full path to the script
script_to_source="$SCRIPT_DIR/$real_filename"

# Source the script
if [ -f "$script_to_source" ]; then
    echo "Sourcing: $script_to_source"
    export ROM_PATH ROM_DIR ROM_FILENAME ROM_FILENAME_NOEXT
    export EMU_DIR EMU_DIR_BASENAME
    export Launcher_name Preset_Type
    . "$script_to_source"
else
    echo "Script not found: $script_to_source"
    return 1
fi
