save_launcher() {
    Emu_cfg="$EMU_DIR/launchers.cfg"
    Launcher_name=$(grep "dowork 0x" "/tmp/log/messages" | tail -n 1 | sed -e 's/.*: \(.*\) dowork 0x.*/\1/')

    if [ -n "$1" ]; then
        GAME=$(basename "$1")
        Cfg_dir="$ROM_DIR/.games_config"
        mkdir -p "$Cfg_dir"
        Game_cfg="$Cfg_dir/${GAME%.*}.cfg"
        echo "launcher=$Launcher_name" >"$Game_cfg"
    else
        echo "default_launcher=$Launcher_name" >"$Emu_cfg"
    fi
}

button_state.sh L
if [ $? -eq 10 ]; then
    save_launcher "$1"
    echo -e "{ \"type\":\"info\", \"size\":2, \"duration\":3000, \"x\":660, \"y\":0,  \"message\":\"Game preset created: $Launcher_name\",  \"icon\":\"\" }" >/tmp/trimui_osd/osd_toast_msg
fi

# Save launcher as default one
button_state.sh R
if [ $? -eq 10 ]; then
    save_launcher
    echo -e "{ \"type\":\"info\", \"size\":2, \"duration\":3000, \"x\":660, \"y\":0,  \"message\":\"Emu preset created: $Launcher_name\",  \"icon\":\"\" }" >/tmp/trimui_osd/osd_toast_msg
fi
