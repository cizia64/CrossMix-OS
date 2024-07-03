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

database_file="/mnt/SDCARD/Apps/SystemTools/Menu/Menu_cache7.db"

sqlite3 "$database_file" "UPDATE Menu_roms SET disp = 'SSH (enabled)',pinyin = 'SSH (enabled)',cpinyin = 'SSH (enabled)',opinyin = 'SSH (enabled)' WHERE disp = 'SSH (disabled)';"
sqlite3 "$database_file" "UPDATE Menu_roms SET ppath = 'SSH (enabled)' WHERE ppath = 'SSH (disabled)';"
sync
json_file="/tmp/state.json"

# we modify the current menu position as the DB entry has changed
jq '.list |= map(if .ppath == "SSH (disabled)" then .ppath = "SSH (enabled)" else . end)' "$json_file" >"$json_file.tmp" && mv "$json_file.tmp" "$json_file"

sleep 1
IP=$(ip route get 1 2>/dev/null | awk '{print $NF;exit}')
echo "SSH server IP: $IP"
/mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "SSH server IP: $IP" -t 4
