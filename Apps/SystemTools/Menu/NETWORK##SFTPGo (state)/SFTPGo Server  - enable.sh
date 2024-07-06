#!/bin/sh
  
/mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "Applying \"$(basename "$0" .sh)\" by default..."

json_file="/mnt/SDCARD/System/etc/crossmix.json"

if [ ! -f "$json_file" ]; then
  echo "{}" >"$json_file"
fi

/mnt/SDCARD/System/bin/jq '. += {"SFTPGo": 1}' "$json_file" >"/tmp/json_file.tmp" && mv "/tmp/json_file.tmp" "$json_file"

sed -i 's/export NETWORK_SFTPGO="N"/export NETWORK_SFTPGO="Y"/' /mnt/SDCARD/System/etc/ex_config
pkill /mnt/SDCARD/System/sftpgo/sftpgo
mkdir -p /opt/sftpgo
nice -2 /mnt/SDCARD/System/sftpgo/sftpgo serve -c /mnt/SDCARD/System/sftpgo/ >/dev/null &

# we modify the DB entries to reflect the current state
/mnt/SDCARD/System/usr/trimui/scripts/mainui_state_update.sh "SFTPGo" "enabled"

sleep 0.5
IP=$(ip route get 1 2>/dev/null | awk '{print $NF;exit}')
echo "SFTPGo: http://$IP:8080"
/mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "SFTPGo: http://$IP:8080" -t 4
