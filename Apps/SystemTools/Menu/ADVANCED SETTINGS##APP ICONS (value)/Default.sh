#!/bin/sh
PATH="/mnt/SDCARD/System/bin:$PATH"
LD_LIBRARY_PATH="/mnt/SDCARD/System/lib:/usr/trimui/lib:$LD_LIBRARY_PATH"

/mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "Applying \"$(basename "$0" .sh)\" app icons by default..."

script_name=$(basename "$0" .sh)

apply_icons() {
    base_path="$1"
    find "$base_path" -name "config.json" -exec sh -c '
        config_json="{}"
        app_dir=$(dirname "$config_json")
        app_name=$(basename "$app_dir")
        
        icons_path="/mnt/SDCARD/Icons/$0/Apps/$app_name.png"
        fallback_icon="$app_dir/icon.png"

        if [ -f "$icons_path" ]; then
            selected_icon="$icons_path"
			echo "  - $app_name -> $selected_icon"
        elif [ -f "$fallback_icon" ]; then
            selected_icon="$fallback_icon"
			echo "  - $app_name (fallback icon) -> $selected_icon"
        else
            echo "  - No icon found for $app_name, skipping."
            exit 0
        fi

        
        /mnt/SDCARD/System/bin/jq \
            --arg new_icon "$selected_icon" \
            --arg empty "" \
            ".icon = \$new_icon | .icontop = \$empty" \
            "$config_json" > /tmp/tmp_config.json && mv /tmp/tmp_config.json "$config_json"
    ' "$script_name" {} \;
}

apply_icons /mnt/SDCARD/Apps/
apply_icons /usr/trimui/apps/

json_file="/mnt/SDCARD/System/etc/crossmix.json"
if [ ! -f "$json_file" ]; then
    echo "{}" > "$json_file"
fi
/mnt/SDCARD/System/bin/jq --arg script_name "$script_name" '. += {"APP ICONS": $script_name}' "$json_file" > "/tmp/json_file.tmp" && mv "/tmp/json_file.tmp" "$json_file"

/mnt/SDCARD/System/usr/trimui/scripts/mainui_state_update.sh "APP ICONS" "$script_name"
