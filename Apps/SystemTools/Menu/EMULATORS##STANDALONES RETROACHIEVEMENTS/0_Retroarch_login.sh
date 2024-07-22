#!/usr/bin/env sh

ConfigFile="/mnt/SDCARD/RetroArch/retroarch.cfg"


Username=$(grep "^cheevos_username" "$ConfigFile" | cut -d '"' -f 2)

if [ -n "$Username" ]; then

	button=$(infoscreen.sh -m "Username $Username is already set.\n\
Do you want to onverwrite it?\n\
A: Yes; B: No" -k "A B" -fs 30
)
    if [ "$button" = "B" ]; then
        exit 0
    fi
fi

commands=$(
	cat <<EOF
escape_string() {
    echo -n "$1" | sed 's/\\/\\\\/g; s/"/\\"/g; s/'\''/\\'\''/g; s/ /\\ /g'
}
echo "Please enter your RetroAchievements username:"
read -r tmp
Username=$(escape_string "$tmp")
sed -i "s/^cheevos_username.*/cheevos_username = \"$Username\"/" "$ConfigFile"
echo "Please enter your RetroAchievements password:"
read -r tmp
Password=$(escape_string "$tmp")
sed -i "s/^cheevos_password.*/cheevos_password = \"$Password\"/" "$ConfigFile"
EOF
)

/mnt/SDCARD/Apps/Terminal/SimpleTerminal -e sh -c "$commands"
