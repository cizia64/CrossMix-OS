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
[ $? -eq 10 ] && save_launcher "$1"

# Save launcher as default one
button_state.sh R
[ $? -eq 10 ] && save_launcher
