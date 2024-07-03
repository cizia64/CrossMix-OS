#!/bin/sh

/mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "Applying \"$(basename "$0" .sh)\" by default..."

json_file="/mnt/SDCARD/System/etc/crossmix.json"

if [ ! -f "$json_file" ]; then
  echo "{}" >"$json_file"
fi

/mnt/SDCARD/System/bin/jq '. += {"SMB": 1, "SMB_secure": 0}' "$json_file" >"/tmp/json_file.tmp" && mv "/tmp/json_file.tmp" "$json_file"

kill -9 $(pidof smbd)
kill -9 $(pidof nmbd)

PATH="/mnt/SDCARD/System/bin:$PATH"
CONFIGFILE="/mnt/SDCARD/System/etc/samba/smb.conf"
export LD_LIBRARY_PATH="/mnt/SDCARD/System/lib:/mnt/SDCARD/System/lib/samba:/usr/trimui/lib:$LD_LIBRARY_PATH"

rm -rf /var/cache/samba /var/log/samba /var/lock/subsys /var/run/samba /var/lib/samba/
mkdir -p /var/cache/samba /var/log/samba /var/lock/subsys /var/run/samba /var/run/samba/locks /var/lib/samba/private
sync
sleep 0.3

smbd -s ${CONFIGFILE} -D
nmbd -D --configfile="${CONFIGFILE}"

# we modify the DB entries to reflect the current state

database_file="/mnt/SDCARD/Apps/SystemTools/Menu/Menu_cache7.db"

sqlite3 "$database_file" "UPDATE Menu_roms SET disp = 'SMB (enabled)',pinyin = 'SMB (enabled)',cpinyin = 'SMB (enabled)',opinyin = 'SMB (enabled)' WHERE disp = 'SMB (disabled)';"
sqlite3 "$database_file" "UPDATE Menu_roms SET ppath = 'SMB (enabled)' WHERE ppath = 'SMB (disabled)';"
sync
json_file="/tmp/state.json"

# we modify the current menu position as the DB entry has changed
jq '.list |= map(if .ppath == "SMB (disabled)" then .ppath = "SMB (enabled)" else . end)' "$json_file" >"$json_file.tmp" && mv "$json_file.tmp" "$json_file"


sleep 1
IP=$(ip route get 1 2>/dev/null | awk '{print $NF;exit}')
echo "SMB: \\\\$IP"
/mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "SMB: \\\\$IP" -fs 50 -t 4
