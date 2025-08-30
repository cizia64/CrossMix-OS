export PATH="/mnt/SDCARD/System/usr/trimui/scripts/:/mnt/SDCARD/System/bin:${PATH:+:$PATH}"
export LD_LIBRARY_PATH="/usr/trimui/lib:${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

EMU_DIR="$(echo "$0" | sed -E 's|(.*Emus/[^/]+)/.*|\1|')"
ROM_DIR="$(echo "$1" | sed -E 's|(.*Roms/[^/]+)/.*|\1|')"
GAME=$(basename "$1")

export Game_cfg="$ROM_DIR/.games_config/${GAME%.*}.cfg"
export Emu_cfg="$EMU_DIR/launchers.cfg"

# Look for a saved preset
if [ -f "$Game_cfg" ]; then
    export Launcher_name=$(cat "$Game_cfg")
    export Preset_Type="Game"

elif [ -f "$Emu_cfg" ]; then
    export Launcher_name=$(cat "$Emu_cfg")
    export Preset_Type="Emu"

fi
Launcher_name=${Launcher_name#*=}

if [ -n "$Launcher_name" ]; then
    Launcher_command=$(jq -r --arg name "$Launcher_name" \
        '.launchlist[] | select(.name == $name) | .launch' "$EMU_DIR/config.json")
    echo -e "{ \"type\":\"info\", \"size\":2, \"duration\":2000, \"x\":660, \"y\":0,  \"message\":\"$Preset_Type preset: $Launcher_name\",  \"icon\":\"\" }" >/tmp/trimui_osd/osd_toast_msg

else
    # Look for the first valid launcher in launchlist
    if jq -e ".launchlist" "$EMU_DIR/config.json" >/dev/null 2>&1; then
        while read launcher; do
            Launcher_name=$(echo "$launcher" | jq -r '.name')
            Launcher_command=$(echo "$launcher" | jq -r '.launch')
            if [ -n "$Launcher_command" ]; then break; fi
        done < <(jq -c '.launchlist[]' "$EMU_DIR/config.json")
    else
        # Else use launch.sh as fallback
        Launcher_name=Default
        Launcher_command="launch.sh"
    fi
fi

echo "load_launcher.sh : $Launcher_name dowork 0x" >>/tmp/log/messages
{
    rm "/tmp/trimui_osd/slider_cpu_preset/curpreset"
    echo "0/3" >"/tmp/trimui_osd/slider_cpu_preset/status"
} &
"$EMU_DIR/$Launcher_command" "$@"
{
    rm "/tmp/trimui_osd/slider_cpu_preset/curpreset"
    echo "0/3" >"/tmp/trimui_osd/slider_cpu_preset/status"
} &
