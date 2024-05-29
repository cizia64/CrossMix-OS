FTP_enabled=$(/mnt/SDCARD/System/bin/jq -r '.["FTP enabled"]' "/mnt/SDCARD/System/etc/crossmix.json")
if [ "$FTP_enabled" -eq 0 ]; then
	echo "The value of 'FTP enabled' is 0."
	 pkill sftpgo
fi

SSH_enabled=$(/mnt/SDCARD/System/bin/jq -r '.["SSH enabled"]' "/mnt/SDCARD/System/etc/crossmix.json")
if [ "$SSH_enabled" -eq 0 ]; then
	echo "The value of 'SSH enabled' is 0."
	 pkill dropbear
fi