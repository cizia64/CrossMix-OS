TELNET_enabled=$(/mnt/SDCARD/System/bin/jq -r '.["TELNET"]' "/mnt/SDCARD/System/etc/crossmix.json")
if [ "$TELNET_enabled" -eq 1 ]; then
	telnetd
fi

Syncthing_enabled=$(/mnt/SDCARD/System/bin/jq -r '.["Syncthing"]' "/mnt/SDCARD/System/etc/crossmix.json")
if [ "$Syncthing_enabled" -eq 1 ]; then
	CONFIGPATH=/mnt/SDCARD/System/etc/syncthing
	/mnt/SDCARD/System/bin/syncthing serve --no-restart --no-upgrade --config="$CONFIGPATH" --data="$CONFIGPATH/data" &
fi
