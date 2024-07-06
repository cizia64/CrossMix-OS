#!/bin/sh
PATH="/mnt/SDCARD/System/bin:$PATH"
export LD_LIBRARY_PATH="/mnt/SDCARD/System/lib:/usr/trimui/lib:$LD_LIBRARY_PATH"

/mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "Applying \"$(basename "$0" .sh)\" by default..."

json_file="/mnt/SDCARD/System/etc/crossmix.json"

if [ ! -f "$json_file" ]; then
  echo "{}" >"$json_file"
fi

/mnt/SDCARD/System/bin/jq '. += {"SSH": 1}' "$json_file" >"/tmp/json_file.tmp" && mv "/tmp/json_file.tmp" "$json_file"

pkill dropbear
sed -i 's/export NETWORK_SSH="N"/export NETWORK_SSH="Y"/' /mnt/SDCARD/System/etc/ex_config
mkdir -p /etc/dropbear
nice -2 dropbear -R

# we modify the DB entries to reflect the current state
/mnt/SDCARD/System/usr/trimui/scripts/mainui_state_update.sh "SSH" "enabled"

sleep 1
IP=$(ip route get 1 2>/dev/null | awk '{print $NF;exit}')
echo "SSH server IP: $IP"
/mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "SSH server IP: $IP" -t 4
