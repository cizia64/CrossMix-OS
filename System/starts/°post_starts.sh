PATH="/mnt/SDCARD/System/bin:$PATH"
export LD_LIBRARY_PATH="/mnt/SDCARD/System/lib:/mnt/SDCARD/System/lib/samba:/mnt/SDCARD/Apps/PortMaster/PortMaster:/usr/trimui/lib:$LD_LIBRARY_PATH"

start_thd_listener() {
	(
		NightMode=$(/mnt/SDCARD/System/bin/jq -r '.["NightMode"]' "/mnt/SDCARD/System/etc/crossmix.json")

		if [ "$NightMode" = "Configurator" ]; then
			if ! pgrep -f nightmode_osdd >/dev/null; then
				cd /mnt/SDCARD/System/usr/trimui/osd/
				/mnt/SDCARD/System/usr/trimui/osd/nightmode_osdd & # The OSD must run before thd
			fi
		fi
		sleep 2
		thd /dev/input/event3 --triggers /mnt/SDCARD/System/etc/shortcuts.conf &

	) &
}
start_thd_listener

if [ -f /tmp/device_changed ]; then
	/mnt/SDCARD/System/usr/trimui/scripts/inputd_switcher.sh
fi

# Swap A B
SWAP_AB_enabled=$(/mnt/SDCARD/System/bin/jq -r '.["SWAP A B"]' "/mnt/SDCARD/System/etc/crossmix.json")
if [ "$SWAP_AB_enabled" -eq 1 ]; then
	mkdir -p /var/trimui_inputd
	touch /var/trimui_inputd/swap_ab
fi

# Telnet service
TELNET_enabled=$(/mnt/SDCARD/System/bin/jq -r '.["TELNET"]' "/mnt/SDCARD/System/etc/crossmix.json")
if [ "$TELNET_enabled" -eq 1 ]; then
	telnetd &
fi

# Syncthing service
Syncthing_enabled=$(/mnt/SDCARD/System/bin/jq -r '.["Syncthing"]' "/mnt/SDCARD/System/etc/crossmix.json")
if [ "$Syncthing_enabled" -eq 1 ]; then
	CONFIGPATH=/mnt/SDCARD/System/etc/syncthing
	/mnt/SDCARD/System/bin/syncthing serve --no-restart --no-upgrade --config="$CONFIGPATH" --data="$CONFIGPATH/data" &
fi

# SMB service
smb_enabled=$(/mnt/SDCARD/System/bin/jq -r '.["SMB"]' "/mnt/SDCARD/System/etc/crossmix.json")
if [ "$smb_enabled" -eq 1 ]; then
	rm -rf /var/cache/samba /var/log/samba /var/lock/subsys /var/run/samba /var/lib/samba/
	mkdir -p /var/cache/samba /var/log/samba /var/lock/subsys /var/run/samba /var/run/samba/locks /var/lib/samba/private

	smb_secure_enabled=$(/mnt/SDCARD/System/bin/jq -r '.["SMB_secure"]' "/mnt/SDCARD/System/etc/crossmix.json")
	if [ "$smb_secure_enabled" -eq 1 ]; then
		CONFIGFILE="/mnt/SDCARD/System/etc/samba/smb-secure.conf"
		echo -e "trimui\ntrimui\n" | smbpasswd -s -a root -c ${CONFIGFILE}
	else
		CONFIGFILE="/mnt/SDCARD/System/etc/samba/smb.conf"
	fi

	wsddn --user root --unixd --smb-conf /mnt/SDCARD/System/etc/samba --log-level 0 &
	smbd -s ${CONFIGFILE} -D &
	nmbd -D --configfile="${CONFIGFILE}" &

fi

# Tailscale service
Tailscale_enabled=$(/mnt/SDCARD/System/bin/jq -r '.["Tailscale"]' "/mnt/SDCARD/System/etc/crossmix.json")
if [ "$Tailscale_enabled" -eq 1 ]; then
	export STATE_DIRECTORY=/mnt/SDCARD/System/etc/tailscale
	/mnt/SDCARD/System/bin/tailscaled --state="/mnt/SDCARD/System/etc/tailscale/tailscaled.state" &
fi

VNC_wait_for_MainUI() {
	timeout=10
	elapsed=0
	while ! pgrep -x "MainUI" >/dev/null; do
		sleep 0.5
		elapsed=$(echo "$elapsed + 0.5" | bc)
		if (($(echo "$elapsed >= $timeout" | bc))); then
			echo "Error: MainUI did not start within $timeout seconds."
			return 1
		fi
	done
	echo "MainUI started."
	touch /tmp/dummy.ini
	/mnt/SDCARD/Apps/PortMaster/PortMaster/gptokeyb2 -c /tmp/dummy.ini &
	sleep 0.5
	vncserver -k /dev/input/event4 &
	return 0
}

# VNC service
VNC_enabled=$(/mnt/SDCARD/System/bin/jq -r '.["VNC"]' "/mnt/SDCARD/System/etc/crossmix.json")
if [ "$VNC_enabled" -eq 1 ]; then
	# Run the function in the background
	VNC_wait_for_MainUI &
fi

# Avahi (DNS name) service
/usr/sbin/avahi-daemon --file=/mnt/SDCARD/System/etc/avahi/avahi-daemon.conf --no-drop-root -D &

# TrimUI In Game Menu state
IngameMenu_enabled=$(/mnt/SDCARD/System/bin/jq -r '.["IN GAME MENU"]' "/mnt/SDCARD/System/etc/crossmix.json")
if [ "$IngameMenu_enabled" -eq 0 ]; then
	mkdir -p /tmp/trimui_ra64/
	touch /tmp/trimui_ra64/disable_tmenu
fi

# SmartLed
SmartLed_enabled=$(/mnt/SDCARD/System/bin/jq -r '.["SMARTLED"]' "/mnt/SDCARD/System/etc/crossmix.json")
if [ "$SmartLed_enabled" -eq 1 ]; then
	cd /mnt/SDCARD/Apps/SmartLed
	./smartledd &
fi

wifi_workaround() {

	TIMEOUT=8                    # in seconds
	INTERVAL=0.5                 # in seconds
	MAX_RETRIES=$((TIMEOUT * 2)) # 0.5s interval → 2 retries per second
	attempt_count=0

	check_ip() {
		ip addr show "wlan0" | grep -q "inet "
	}

	wait_for_ip() {
		count=0
		while [ $count -lt $MAX_RETRIES ]; do
			if check_ip; then
				echo "[OK] IP address found on wlan0"
				return 0
			else
				attempt_count=$((attempt_count + 1))
			fi
			sleep $INTERVAL
			count=$((count + 1))
		done
		return 1
	}

	sleep 6 # necessary for hardwareservice initialization
	echo "[INFO] Checking if wlan0 has an IP address..."
	if ! check_ip; then
		echo "[INFO] No IP found. Triggering Wi-Fi ON..."
		touch "/tmp/system/wifi_turn_on"

		if ! wait_for_ip; then
			echo "[WARN] Still no IP after first attempt. Cycling Wi-Fi..."
			pgrep hardwareservice >/dev/null || /usr/trimui/bin/hardwareservice &
			sleep 1
			touch "/tmp/system/wifi_turn_off"
			sleep 2
			touch "/tmp/system/wifi_turn_on"

			if check_ip; then
				echo "IP acquired after $attempt_count attempt(s)."
			else
				echo "[FAIL] No IP address acquired after $attempt_count attempts. Aborting."
			fi
		else
			echo "[INFO] IP address already present on wlan0."
		fi
	else
		echo "[INFO] IP address already present on wlan0."
	fi
}

# hardwareservice race condition workaround for wifi initialization
wifi_value=$(/usr/trimui/bin/systemval wifi)
if [ "$wifi_value" -eq 1 ]; then
	wifi_workaround & # for debugging: wifi_workaround >>/tmp/wifi_debug.log 2>&1 &
fi
