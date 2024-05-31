#!/bin/sh

/mnt/SDCARD/System/bin/sdl2imgshow \
  -i "/mnt/SDCARD/trimui/res/crossmix-os/bg-info.png" \
  -f "/mnt/SDCARD/System/resources/DejaVuSans.ttf" \
  -s 50 \
  -c "220,220,220" \
  -t "Applying \"$(basename "$0" .sh)\" by default..." &

json_file="/mnt/SDCARD/System/etc/crossmix.json"

if [ ! -f "$json_file" ]; then
  echo "{}" >"$json_file"
fi

/mnt/SDCARD/System/bin/jq '. += {"SFTPGo": 1}' "$json_file" >"/tmp/json_file.tmp" && mv "/tmp/json_file.tmp" "$json_file"

pkill sftpgo
mkdir -p /opt/sftpgo
nice -2 /mnt/SDCARD/System/sftpgo/sftpgo serve -c /mnt/SDCARD/System/sftpgo/ >/dev/null &

# we modify the DB entries to reflect the current state
PATH="/mnt/SDCARD/System/bin:$PATH"
export LD_LIBRARY_PATH="/mnt/SDCARD/System/lib:/usr/trimui/lib:$LD_LIBRARY_PATH"
database_file="/mnt/SDCARD/Apps/SystemTools/Menu/Menu_cache7.db"

sqlite3 "$database_file" "UPDATE Menu_roms SET disp = 'SFTPGo (enabled)',pinyin = 'SFTPGo (enabled)',cpinyin = 'SFTPGo (enabled)',opinyin = 'SFTPGo (enabled)' WHERE disp = 'SFTPGo (disabled)';"
sqlite3 "$database_file" "UPDATE Menu_roms SET ppath = 'SFTPGo (enabled)' WHERE ppath = 'SFTPGo (disabled)';"
sync
json_file="/tmp/state.json"

# we modify the current menu position as the DB entry has changed
jq '.list |= map(if .ppath == "SFTPGo (disabled)" then .ppath = "SFTPGo (enabled)" else . end)' "$json_file" >"$json_file.tmp" && mv "$json_file.tmp" "$json_file"

sleep 0.1
pkill -f sdl2imgshow
sleep 0.3
IP=$(ip route get 1 2>/dev/null | awk '{print $NF;exit}')
echo "SFTPGo: http://$IP:8080"
/mnt/SDCARD/System/bin/sdl2imgshow \
  -i "/mnt/SDCARD/trimui/res/crossmix-os/bg-info.png" \
  -f "/mnt/SDCARD/System/resources/DejaVuSans.ttf" \
  -s 50 \
  -c "220,220,220" \
  -t "SFTPGo: http://$IP:8080" &

sleep 4
pkill -f sdl2imgshow
