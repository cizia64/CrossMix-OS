PATH="/mnt/SDCARD/System/bin:$PATH"
export LD_LIBRARY_PATH="/mnt/SDCARD/System/lib:/mnt/SDCARD/System/lib/samba:/usr/trimui/lib:$LD_LIBRARY_PATH"

# Swap A B
SWAP_AB_enabled=$(/mnt/SDCARD/System/bin/jq -r '["SWAP A B"]' "/mnt/SDCARD/System/etc/crossmix.json")
if [ "$SWAP_AB_enabled" -eq 1 ]; then
  mkdir -p /var/trimui_inputd
  touch /var/trimui_inputd/swap_ab
fi

# Telnet service
TELNET_enabled=$(/mnt/SDCARD/System/bin/jq -r '.["TELNET"]' "/mnt/SDCARD/System/etc/crossmix.json")
if [ "$TELNET_enabled" -eq 1 ]; then
	telnetd
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

	smbd -s ${CONFIGFILE} -D
	nmbd -D --configfile="${CONFIGFILE}"

fi

# Tailscale service
Tailscale_enabled=$(/mnt/SDCARD/System/bin/jq -r '.["Tailscale"]' "/mnt/SDCARD/System/etc/crossmix.json")
if [ "$Tailscale_enabled" -eq 1 ]; then
	/mnt/SDCARD/System/bin/tailscaled &
fi

# Avahi (DNS name) service
/usr/sbin/avahi-daemon --file=/mnt/SDCARD/System/etc/avahi/avahi-daemon.conf  --no-drop-root -D
