#!/usr/bin/env sh

export PATH="$PATH:/mnt/SDCARD/System/usr/trimui/scripts"
ConfigFile="/mnt/SDCARD/RetroArch/retroarch.cfg"

Username=$(grep "^cheevos_username" "$ConfigFile" | cut -d '"' -f 2)

if [ -n "$Username" ]; then

	button=$(
		infoscreen.sh -m "Username $Username is already set.\
Do you want to onverwrite it?\
A: Yes; B: No" -k "A B" -fs 30
	)
	if [ "$button" = "B" ]; then
		exit 0
	fi
fi

infoscreen.sh -m "Terminal will open to set your credentials. Press X to open keyboard and L to shift." -k "A B START MENU" -fs 30

pipe=/tmp/fifo
mkfifo "$pipe"
(
	cat <<'EOF'
#!/usr/bin/env sh

escape_string() {
    echo -n "$1" | sed 's/\\/\\\\/g; s/"/\\"/g; s/'\''/\\'\''/g; s/ /\\ /g'
}

ConfigFile="/mnt/SDCARD/RetroArch/retroarch.cfg"

echo "Please enter your RetroAchievements username:"
read -r tmp
Username=$(escape_string "$tmp")
sed -i "s/^cheevos_username.*/cheevos_username = \"$Username\"/" "$ConfigFile"
echo "Please enter your RetroAchievements password:"
read -r tmp
Password=$(escape_string "$tmp")
sed -i "s/^cheevos_password.*/cheevos_password = \"$Password\"/" "$ConfigFile"
exit 0
EOF
) >"$pipe" &

/mnt/SDCARD/Apps/Terminal/SimpleTerminal -e "sh $pipe"
rm -f $pipe
